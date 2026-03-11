import prisma from '../shared/prisma';
import { nanoid } from 'nanoid';

export interface CreateOrganizationData {
  name: string;
  userId: string;
}

/**
 * Create a new organization with the user as owner
 */
export async function createOrganization(data: CreateOrganizationData) {
  const { name, userId } = data;

  // Generate a unique slug from the name
  const baseSlug = name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  const slug = `${baseSlug}-${nanoid(6)}`;

  const organization = await prisma.$transaction(async (tx) => {
    // Create the user if it doesn't exist (upsert)
    await tx.user.upsert({
      where: { id: userId },
      update: {},
      create: {
        id: userId,
        email: `user-${userId.slice(0, 8)}@example.com`,
        name: 'User',
        password: 'placeholder',
      },
    });

    // Create the organization
    const org = await tx.organization.create({
      data: {
        name,
        slug,
      },
    });

    // Add the creator as owner
    await tx.organizationMember.create({
      data: {
        userId,
        organizationId: org.id,
        role: 'owner',
      },
    });

    return org;
  });

  return organization;
}

/**
 * Get organizations for a user
 */
export async function getUserOrganizations(userId: string) {
  const memberships = await prisma.organizationMember.findMany({
    where: { userId },
    include: {
      organization: {
        include: {
          members: {
            select: {
              id: true,
              userId: true,
              role: true,
              joinedAt: true,
              user: {
                select: {
                  id: true,
                  name: true,
                  email: true,
                },
              },
            },
          },
        },
      },
    },
    orderBy: { joinedAt: 'asc' },
  });

  return memberships.map((m) => ({
    ...m.organization,
    userRole: m.role,
  }));
}

/**
 * Accept an invitation and join organization
 */
export async function acceptInvitation(token: string, userId: string) {
  const invitation = await prisma.invitation.findUnique({
    where: { token },
    include: { organization: true },
  });

  if (!invitation) {
    throw new Error('Invalid invitation token');
  }

  if (invitation.status !== 'pending') {
    throw new Error('Invitation is no longer valid');
  }

  if (invitation.expiresAt < new Date()) {
    await prisma.invitation.update({
      where: { id: invitation.id },
      data: { status: 'expired' },
    });
    throw new Error('Invitation has expired');
  }

  // Add user as member
  await prisma.$transaction(async (tx) => {
    await tx.organizationMember.create({
      data: {
        userId,
        organizationId: invitation.organizationId,
        role: 'member',
      },
    });

    await tx.invitation.update({
      where: { id: invitation.id },
      data: {
        status: 'accepted',
        acceptedAt: new Date(),
      },
    });
  });

  return invitation.organization;
}
