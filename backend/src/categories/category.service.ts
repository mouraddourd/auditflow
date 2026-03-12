import prisma from '../shared/prisma';

export interface CreateCategoryData {
  id: string;
  name: string;
  description?: string;
  color?: string;
  organizationId: string;
}

export interface UpdateCategoryData {
  name?: string;
  description?: string;
  color?: string;
}

/**
 * Create a category
 */
export async function createCategory(data: CreateCategoryData) {
  const { id, name, description, color, organizationId } = data;

  const category = await prisma.category.create({
    data: {
      id,
      name,
      description,
      color,
      organizationId,
    },
  });

  return category;
}

/**
 * Get categories for an organization
 */
export async function getCategories(organizationId: string) {
  const categories = await prisma.category.findMany({
    where: { organizationId },
    orderBy: { name: 'asc' },
  });

  return categories;
}

/**
 * Get category by ID
 */
export async function getCategoryById(categoryId: string) {
  const category = await prisma.category.findUnique({
    where: { id: categoryId },
  });

  return category;
}

/**
 * Update a category
 */
export async function updateCategory(categoryId: string, data: UpdateCategoryData) {
  const category = await prisma.category.update({
    where: { id: categoryId },
    data,
  });

  return category;
}

/**
 * Delete a category
 */
export async function deleteCategory(categoryId: string) {
  await prisma.category.delete({
    where: { id: categoryId },
  });

  return { success: true };
}
