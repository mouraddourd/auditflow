import prisma from './prisma';

/** Ensure user is a member of an organization; throws if not */
export async function assertOrgMember(userId: string, organizationId: string) {
  const membership = await prisma.organizationMember.findFirst({
    where: { userId, organizationId },
    select: { id: true, role: true },
  });

  if (!membership) {
    throw new Error('Forbidden: user not in organization');
  }

  return membership;
}

/** Ensure a template belongs to an organization and user is member */
export async function assertTemplateAccess(
  userId: string,
  templateId: string,
  organizationId?: string
) {
  const template = await prisma.template.findUnique({
    where: { id: templateId },
    select: { id: true, organizationId: true },
  });
  if (!template) throw new Error('Template not found');
  const orgId = organizationId ?? template.organizationId;
  await assertOrgMember(userId, orgId);
  return orgId;
}

/** Ensure an audit belongs to an organization and user is member */
export async function assertAuditAccess(
  userId: string,
  auditId: string,
  organizationId?: string
) {
  const audit = await prisma.audit.findUnique({
    where: { id: auditId },
    select: { id: true, organizationId: true },
  });
  if (!audit) throw new Error('Audit not found');
  const orgId = organizationId ?? audit.organizationId;
  await assertOrgMember(userId, orgId);
  return orgId;
}

/** Ensure a category belongs to an organization and user is member */
export async function assertCategoryAccess(
  userId: string,
  categoryId: string,
  organizationId?: string
) {
  const category = await prisma.category.findUnique({
    where: { id: categoryId },
    select: { id: true, organizationId: true },
  });
  if (!category) throw new Error('Category not found');
  const orgId = organizationId ?? category.organizationId;
  await assertOrgMember(userId, orgId);
  return orgId;
}
