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

export interface CreateInvitationData {
  organizationId: string;
  email: string;
  invitedBy: string;
}

/**
 * Create an invitation to join an organization
 * Returns the invitation with token for sharing
 */
export async function createInvitation(data: CreateInvitationData) {
  const { organizationId, email, invitedBy } = data;

  // Verify user is admin/owner of the organization
  const membership = await prisma.organizationMember.findFirst({
    where: { organizationId, userId: invitedBy },
  });

  if (!membership || !['owner', 'admin'].includes(membership.role)) {
    throw new Error('Only owners and admins can invite members');
  }

  // Check if user is already a member
  const existingMember = await prisma.organizationMember.findFirst({
    where: { organizationId, user: { email } },
  });

  if (existingMember) {
    throw new Error('User is already a member of this organization');
  }

  // Generate unique token (16 chars for short links)
  const token = nanoid(16);

  // Expires in 7 days
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7);

  const invitation = await prisma.invitation.create({
    data: {
      email,
      organizationId,
      invitedBy,
      token,
      expiresAt,
    },
    include: {
      organization: { select: { id: true, name: true } },
      invitedByUser: { select: { id: true, name: true, email: true } },
    },
  });

  return invitation;
}

/**
 * Get invitation info by token (public, no auth required)
 * Used to display invitation details before login/register
 */
export async function getInvitationInfo(token: string) {
  const invitation = await prisma.invitation.findUnique({
    where: { token },
    include: {
      organization: { select: { id: true, name: true } },
      invitedByUser: { select: { id: true, name: true } },
    },
  });

  if (!invitation) {
    throw new Error('Invitation not found');
  }

  // Check if expired
  if (invitation.expiresAt < new Date()) {
    await prisma.invitation.update({
      where: { id: invitation.id },
      data: { status: 'expired' },
    });
    throw new Error('This invitation has expired');
  }

  // Check if already used
  if (invitation.status !== 'pending') {
    throw new Error('This invitation has already been used');
  }

  return {
    id: invitation.id,
    email: invitation.email,
    organization: invitation.organization,
    invitedBy: invitation.invitedByUser,
    expiresAt: invitation.expiresAt,
  };
}

/**
 * List invitations for an organization (admin only)
 */
export async function getOrganizationInvitations(
  organizationId: string,
  userId: string,
) {
  // Verify user is admin/owner
  const membership = await prisma.organizationMember.findFirst({
    where: { organizationId, userId },
  });

  if (!membership || !['owner', 'admin'].includes(membership.role)) {
    throw new Error('Only owners and admins can view invitations');
  }

  const invitations = await prisma.invitation.findMany({
    where: { organizationId },
    include: {
      invitedByUser: { select: { id: true, name: true, email: true } },
    },
    orderBy: { createdAt: 'desc' },
  });

  return invitations;
}

/**
 * Delete/cancel an invitation (admin only)
 */
export async function deleteInvitation(
  invitationId: string,
  userId: string,
) {
  const invitation = await prisma.invitation.findUnique({
    where: { id: invitationId },
  });

  if (!invitation) {
    throw new Error('Invitation not found');
  }

  // Verify user is admin/owner of the organization
  const membership = await prisma.organizationMember.findFirst({
    where: { organizationId: invitation.organizationId, userId },
  });

  if (!membership || !['owner', 'admin'].includes(membership.role)) {
    throw new Error('Only owners and admins can cancel invitations');
  }

  await prisma.invitation.delete({
    where: { id: invitationId },
  });

  return { success: true };
}
