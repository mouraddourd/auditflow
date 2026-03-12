import prisma from '../shared/prisma';

export interface CreateTemplateData {
  id: string;
  name: string;
  description?: string;
  category?: string;
  userId: string;
  organizationId: string;
  isPublic?: boolean;
  questions: CreateQuestionData[];
}

export interface CreateQuestionData {
  id: string;
  type: string;
  text: string;
  order: number;
  required: boolean;
  options?: any;
}

export interface UpdateTemplateData {
  name?: string;
  description?: string;
  category?: string;
  isPublic?: boolean;
  questions?: CreateQuestionData[];
}

/**
 * Create a template with questions
 */
export async function createTemplate(data: CreateTemplateData) {
  const { id, name, description, category, userId, organizationId, isPublic, questions } = data;

  const template = await prisma.template.create({
    data: {
      id,
      name,
      description,
      category,
      userId,
      organizationId,
      isPublic: isPublic ?? false,
      questions: {
        create: questions.map((q) => ({
          id: q.id,
          type: q.type,
          text: q.text,
          order: q.order,
          required: q.required,
          options: q.options,
        })),
      },
    },
    include: {
      questions: {
        orderBy: { order: 'asc' },
      },
    },
  });

  return template;
}

/**
 * Get templates for an organization
 */
export async function getTemplates(organizationId: string, userId?: string) {
  const templates = await prisma.template.findMany({
    where: {
      OR: [
        { organizationId },
        { isPublic: true },
      ],
    },
    include: {
      questions: {
        orderBy: { order: 'asc' },
      },
      user: {
        select: { id: true, name: true, email: true },
      },
    },
    orderBy: { updatedAt: 'desc' },
  });

  return templates;
}

/**
 * Get template by ID
 */
export async function getTemplateById(templateId: string) {
  const template = await prisma.template.findUnique({
    where: { id: templateId },
    include: {
      questions: {
        orderBy: { order: 'asc' },
      },
      user: {
        select: { id: true, name: true, email: true },
      },
    },
  });

  return template;
}

/**
 * Update a template
 */
export async function updateTemplate(templateId: string, data: UpdateTemplateData) {
  const { name, description, category, isPublic, questions } = data;

  // If questions provided, replace all questions
  if (questions) {
    // Delete existing questions
    await prisma.question.deleteMany({
      where: { templateId },
    });

    // Create new questions
    await prisma.question.createMany({
      data: questions.map((q) => ({
        id: q.id,
        templateId,
        type: q.type,
        text: q.text,
        order: q.order,
        required: q.required,
        options: q.options,
      })),
    });
  }

  const template = await prisma.template.update({
    where: { id: templateId },
    data: {
      name,
      description,
      category,
      isPublic,
    },
    include: {
      questions: {
        orderBy: { order: 'asc' },
      },
    },
  });

  return template;
}

/**
 * Delete a template
 */
export async function deleteTemplate(templateId: string) {
  await prisma.template.delete({
    where: { id: templateId },
  });

  return { success: true };
}
