import { Router, Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../shared/prisma';

const router = Router();

// Schema pour valider les changements PowerSync
const powerSyncChangeSchema = z.object({
  op: z.enum(['INSERT', 'UPDATE', 'DELETE']),
  table: z.enum(['audits', 'answers', 'templates', 'questions']),
  id: z.string(),
  data: z.record(z.string(), z.any()).optional(),
});

const uploadBatchSchema = z.object({
  changes: z.array(powerSyncChangeSchema),
  userId: z.string(),
});

/**
 * POST /powersync/upload - Reçoit les changements du client PowerSync
 * et les applique à PostgreSQL via Prisma
 */
router.post('/upload', async (req: Request, res: Response) => {
  try {
    const { changes, userId } = uploadBatchSchema.parse(req.body);

    const results = await prisma.$transaction(async (tx) => {
      const applied: string[] = [];
      const errors: string[] = [];

      for (const change of changes) {
        try {
          switch (change.table) {
            case 'audits':
              await applyAuditChange(tx, change, userId);
              break;
            case 'answers':
              await applyAnswerChange(tx, change, userId);
              break;
            case 'templates':
              await applyTemplateChange(tx, change, userId);
              break;
            case 'questions':
              await applyQuestionChange(tx, change, userId);
              break;
          }
          applied.push(change.id);
        } catch (err) {
          const message = err instanceof Error ? err.message : 'Unknown error';
          errors.push(`${change.id}: ${message}`);
        }
      }

      return { applied, errors };
    });

    res.json({
      success: results.errors.length === 0,
      applied: results.applied,
      errors: results.errors,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

// Applique un changement sur la table audits
async function applyAuditChange(
  tx: any,
  change: z.infer<typeof powerSyncChangeSchema>,
  userId: string
) {
  const data = change.data || {};

  // Vérifier que l'utilisateur a le droit de modifier cet audit
  if (change.op !== 'INSERT') {
    const existing = await tx.audit.findFirst({
      where: { id: change.id, userId },
    });
    if (!existing) {
      throw new Error('Audit not found or access denied');
    }
  }

  switch (change.op) {
    case 'INSERT':
      // Vérifier que le template appartient à l'utilisateur ou est public
      const template = await tx.template.findFirst({
        where: { id: data.template_id },
      });
      if (!template) {
        throw new Error('Template not found');
      }
      if (template.userId !== userId && !template.isPublic) {
        throw new Error('Access denied: template not owned by user');
      }

      await tx.audit.create({
        data: {
          id: change.id,
          title: data.title,
          description: data.description,
          status: data.status || 'draft',
          score: data.score,
          template: { connect: { id: data.template_id } },
          user: { connect: { id: data.user_id || userId } },
          startedAt: typeof data.started_at === 'string' || typeof data.started_at === 'number' ? new Date(data.started_at) : null,
          completedAt: typeof data.completed_at === 'string' || typeof data.completed_at === 'number' ? new Date(data.completed_at) : null,
          createdAt: typeof data.created_at === 'string' || typeof data.created_at === 'number' ? new Date(data.created_at) : new Date(),
          updatedAt: typeof data.updated_at === 'string' || typeof data.updated_at === 'number' ? new Date(data.updated_at) : new Date(),
        },
      });
      break;

    case 'UPDATE':
      await tx.audit.update({
        where: { id: change.id },
        data: {
          title: data.title,
          description: data.description,
          status: data.status,
          score: data.score,
          startedAt: typeof data.started_at === 'string' || typeof data.started_at === 'number' ? new Date(data.started_at) : undefined,
          completedAt: typeof data.completed_at === 'string' || typeof data.completed_at === 'number' ? new Date(data.completed_at) : undefined,
          updatedAt: new Date(),
        },
      });
      break;

    case 'DELETE':
      await tx.audit.delete({
        where: { id: change.id },
      });
      break;
  }
}

// Applique un changement sur la table answers
async function applyAnswerChange(
  tx: any,
  change: z.infer<typeof powerSyncChangeSchema>,
  userId: string
) {
  const data = change.data || {};

  // Vérifier que l'audit appartient à l'utilisateur pour INSERT
  if (change.op === 'INSERT' && data.audit_id) {
    const audit = await tx.audit.findFirst({
      where: { id: data.audit_id, userId },
    });
    if (!audit) {
      throw new Error('Audit not found or access denied');
    }
  }

  // Vérifier l'accès pour UPDATE/DELETE
  if (change.op !== 'INSERT') {
    const existingAnswer = await tx.answer.findFirst({
      where: { id: change.id },
      include: { audit: true },
    });
    if (!existingAnswer || existingAnswer.audit.userId !== userId) {
      throw new Error('Answer not found or access denied');
    }
  }

  switch (change.op) {
    case 'INSERT':
      await tx.answer.create({
        data: {
          id: change.id,
          audit: { connect: { id: data.audit_id } },
          question: { connect: { id: data.question_id } },
          value: data.value,
          comment: data.comment,
          score: data.score,
          createdAt: typeof data.created_at === 'string' || typeof data.created_at === 'number' ? new Date(data.created_at) : new Date(),
          updatedAt: typeof data.updated_at === 'string' || typeof data.updated_at === 'number' ? new Date(data.updated_at) : new Date(),
        },
      });
      break;

    case 'UPDATE':
      await tx.answer.update({
        where: { id: change.id },
        data: {
          value: data.value,
          comment: data.comment,
          score: data.score,
          updatedAt: new Date(),
        },
      });
      break;

    case 'DELETE':
      await tx.answer.delete({
        where: { id: change.id },
      });
      break;
  }
}

// Applique un changement sur la table templates
async function applyTemplateChange(
  tx: any,
  change: z.infer<typeof powerSyncChangeSchema>,
  userId: string
) {
  const data = change.data || {};

  // Vérifier l'accès pour UPDATE/DELETE
  if (change.op !== 'INSERT') {
    const existing = await tx.template.findFirst({
      where: { id: change.id, userId },
    });
    if (!existing) {
      throw new Error('Template not found or access denied');
    }
  }

  switch (change.op) {
    case 'INSERT':
      await tx.template.create({
        data: {
          id: change.id,
          name: data.name,
          description: data.description,
          category: data.category,
          user: { connect: { id: data.user_id || userId } },
          isPublic: data.is_public === 1 || data.is_public === true,
          createdAt: typeof data.created_at === 'string' || typeof data.created_at === 'number' ? new Date(data.created_at) : new Date(),
          updatedAt: typeof data.updated_at === 'string' || typeof data.updated_at === 'number' ? new Date(data.updated_at) : new Date(),
        },
      });
      break;

    case 'UPDATE':
      await tx.template.update({
        where: { id: change.id },
        data: {
          name: data.name,
          description: data.description,
          category: data.category,
          isPublic: data.is_public !== undefined ? (data.is_public === 1 || data.is_public === true) : undefined,
          updatedAt: new Date(),
        },
      });
      break;

    case 'DELETE':
      await tx.template.delete({
        where: { id: change.id },
      });
      break;
  }
}

// Applique un changement sur la table questions
async function applyQuestionChange(
  tx: any,
  change: z.infer<typeof powerSyncChangeSchema>,
  userId: string
) {
  const data = change.data || {};

  // Vérifier que le template appartient à l'utilisateur
  if (data.template_id) {
    const template = await tx.template.findFirst({
      where: { id: data.template_id, userId },
    });
    if (!template) {
      throw new Error('Template not found or access denied');
    }
  }

  switch (change.op) {
    case 'INSERT':
      await tx.question.create({
        data: {
          id: change.id,
          template: { connect: { id: data.template_id } },
          type: data.type,
          text: data.text,
          order: data.order || 0,
          required: data.required === 1 || data.required === true,
          createdAt: typeof data.created_at === 'string' || typeof data.created_at === 'number' ? new Date(data.created_at) : new Date(),
        },
      });
      break;

    case 'UPDATE':
      await tx.question.update({
        where: { id: change.id },
        data: {
          text: data.text,
          order: data.order,
          required: data.required !== undefined ? (data.required === 1 || data.required === true) : undefined,
        },
      });
      break;

    case 'DELETE':
      await tx.question.delete({
        where: { id: change.id },
      });
      break;
  }
}

export default router;
