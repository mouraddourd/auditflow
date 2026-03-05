import prisma from '../shared/prisma';
import { z } from 'zod';

export interface ListAuditsParams {
  userId: string;
  limit?: number;
  offset?: number;
  status?: 'draft' | 'in_progress' | 'completed';
  minScore?: number;
  maxScore?: number;
  search?: string;
  sortBy?: 'createdAt' | 'updatedAt' | 'score' | 'title';
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResult<T> {
  data: T[];
  pagination: {
    total: number;
    limit: number;
    offset: number;
    hasMore: boolean;
  };
}

const auditFiltersSchema = z.object({
  limit: z.coerce.number().min(1).max(100).default(20),
  offset: z.coerce.number().min(0).default(0),
  status: z.enum(['draft', 'in_progress', 'completed']).optional(),
  minScore: z.coerce.number().min(0).max(100).optional(),
  maxScore: z.coerce.number().min(0).max(100).optional(),
  search: z.string().optional(),
  sortBy: z.enum(['createdAt', 'updatedAt', 'score', 'title']).default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
});

export async function listAudits(params: ListAuditsParams): Promise<PaginatedResult<any>> {
  const {
    userId,
    limit: parsedLimit,
    offset: parsedOffset,
    status,
    minScore,
    maxScore,
    search,
    sortBy = 'createdAt',
    sortOrder = 'desc',
  } = params;

  const filters = auditFiltersSchema.parse({ limit: parsedLimit, offset: parsedOffset, status, minScore, maxScore, search, sortBy, sortOrder });
  
  const { limit, offset } = filters;

  const where: any = {
    userId,
  };

  if (status) {
    where.status = status;
  }

  if (minScore !== undefined || maxScore !== undefined) {
    where.score = {};
    if (minScore !== undefined) where.score.gte = minScore;
    if (maxScore !== undefined) where.score.lte = maxScore;
  }

  if (search) {
    where.OR = [
      { title: { contains: search, mode: 'insensitive' } },
      { description: { contains: search, mode: 'insensitive' } },
    ];
  }

  const [audits, total] = await Promise.all([
    prisma.audit.findMany({
      where,
      include: {
        template: {
          select: {
            id: true,
            name: true,
            category: true,
          },
        },
      },
      orderBy: { [sortBy]: sortOrder },
      take: limit,
      skip: offset,
    }),
    prisma.audit.count({ where }),
  ]);

  return {
    data: audits,
    pagination: {
      total,
      limit,
      offset,
      hasMore: offset + limit < total,
    },
  };
}

export async function getAuditById(auditId: string, userId: string) {
  return prisma.audit.findFirst({
    where: {
      id: auditId,
      userId,
    },
    include: {
      template: {
        include: {
          questions: {
            orderBy: { order: 'asc' },
          },
        },
      },
      answers: {
        include: {
          question: true,
        },
      },
    },
  });
}

export async function createAudit(data: {
  title: string;
  description?: string;
  templateId: string;
  userId: string;
}) {
  return prisma.audit.create({
    data: {
      title: data.title,
      description: data.description,
      templateId: data.templateId,
      userId: data.userId,
      status: 'draft',
    },
    include: {
      template: true,
    },
  });
}

export async function updateAuditStatus(
  auditId: string,
  userId: string,
  status: 'draft' | 'in_progress' | 'completed'
) {
  const updateData: any = { status };

  if (status === 'in_progress') {
    updateData.startedAt = new Date();
  } else if (status === 'completed') {
    updateData.completedAt = new Date();
  }

  const result = await prisma.audit.updateMany({
    where: {
      id: auditId,
      userId,
    },
    data: updateData,
  });

  if (result.count === 0) {
    throw new Error('Audit not found or access denied');
  }

  return result;
}

export async function deleteAudit(auditId: string, userId: string) {
  const result = await prisma.audit.deleteMany({
    where: {
      id: auditId,
      userId,
    },
  });

  if (result.count === 0) {
    throw new Error('Audit not found or access denied');
  }

  return result;
}

export async function getAuditStats(userId: string) {
  const [total, completed, inProgress, draft, avgScore] = await Promise.all([
    prisma.audit.count({ where: { userId } }),
    prisma.audit.count({ where: { userId, status: 'completed' } }),
    prisma.audit.count({ where: { userId, status: 'in_progress' } }),
    prisma.audit.count({ where: { userId, status: 'draft' } }),
    prisma.audit.aggregate({
      where: { userId, status: 'completed', score: { not: null } },
      _avg: { score: true },
    }),
  ]);

  return {
    total,
    completed,
    inProgress,
    draft,
    avgScore: avgScore._avg.score ?? 0,
  };
}
