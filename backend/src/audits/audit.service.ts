import prisma from '../shared/prisma';

export interface CreateAuditData {
  id: string;
  title: string;
  description?: string;
  templateId: string;
  userId: string;
  organizationId: string;
  status?: string;
  score?: number;
}

export interface CreateAnswerData {
  id: string;
  questionId: string;
  value: string;
  comment?: string;
  score?: number;
}

export interface UpdateAuditData {
  title?: string;
  description?: string;
  status?: string;
  score?: number;
  startedAt?: Date;
  completedAt?: Date;
}

/**
 * Create an audit
 */
export async function createAudit(data: CreateAuditData) {
  const { id, title, description, templateId, userId, organizationId, status, score } = data;

  const audit = await prisma.audit.create({
    data: {
      id,
      title,
      description,
      templateId,
      userId,
      organizationId,
      status: status ?? 'draft',
      score,
    },
    include: {
      template: {
        include: {
          questions: {
            orderBy: { order: 'asc' },
          },
        },
      },
      answers: true,
    },
  });

  return audit;
}

/**
 * Get audits for an organization
 */
export async function getAudits(organizationId: string, userId?: string, status?: string) {
  const where: any = { organizationId };

  if (status) {
    where.status = status;
  }

  const audits = await prisma.audit.findMany({
    where,
    include: {
      template: {
        select: { id: true, name: true, category: true },
      },
      user: {
        select: { id: true, name: true, email: true },
      },
      _count: {
        select: { answers: true },
      },
    },
    orderBy: { updatedAt: 'desc' },
  });

  return audits;
}

/**
 * Get audit by ID
 */
export async function getAuditById(auditId: string) {
  const audit = await prisma.audit.findUnique({
    where: { id: auditId },
    include: {
      template: {
        include: {
          questions: {
            orderBy: { order: 'asc' },
          },
        },
      },
      answers: true,
      user: {
        select: { id: true, name: true, email: true },
      },
    },
  });

  return audit;
}

/**
 * Update audit status
 */
export async function updateAudit(auditId: string, data: UpdateAuditData) {
  const audit = await prisma.audit.update({
    where: { id: auditId },
    data,
    include: {
      template: {
        select: { id: true, name: true },
      },
    },
  });

  return audit;
}

/**
 * Save answers for an audit (batch upsert)
 */
export async function saveAnswers(auditId: string, answers: CreateAnswerData[]) {
  // Ensure audit exists and belongs to expected org
  const audit = await prisma.audit.findUnique({
    where: { id: auditId },
    select: { id: true, organizationId: true, templateId: true },
  });
  if (!audit) throw new Error('Audit not found');

  // Ensure questions belong to the audit template
  const templateQuestions = await prisma.question.findMany({
    where: { templateId: audit.templateId },
    select: { id: true },
  });
  const validQuestionIds = new Set(templateQuestions.map((q) => q.id));

  const invalid = answers.find((a) => !validQuestionIds.has(a.questionId));
  if (invalid) {
    throw new Error('Invalid questionId for this audit');
  }

  // Upsert each answer
  const operations = answers.map((answer) =>
    prisma.answer.upsert({
      where: { id: answer.id },
      create: {
        id: answer.id,
        auditId,
        questionId: answer.questionId,
        value: answer.value,
        comment: answer.comment,
        score: answer.score,
      },
      update: {
        value: answer.value,
        comment: answer.comment,
        score: answer.score,
      },
    })
  );

  await prisma.$transaction(operations);

  // Return updated audit with answers
  return getAuditById(auditId);
}

/**
 * Delete an audit
 */
export async function deleteAudit(auditId: string) {
  await prisma.audit.delete({
    where: { id: auditId },
  });

  return { success: true };
}
