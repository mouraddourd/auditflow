import prisma from '../shared/prisma';
import { nanoid } from 'nanoid';

export interface CreateOrganizationData {
  name: string;
  userId: string;
}

export interface InviteMemberData {
  email: string;
  organizationId: string;
  invitedBy: string;
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
 * Get organization by ID (only if user is member)
 */
export async function getOrganizationById(organizationId: string, userId: string) {
  const membership = await prisma.organizationMember.findFirst({
    where: {
      organizationId,
      userId,
    },
    include: {
      organization: true,
    },
  });

  if (!membership) {
    return null;
  }

  return {
    ...membership.organization,
    userRole: membership.role,
  };
}

/**
 * Invite a member to an organization
 */
export async function inviteMember(data: InviteMemberData) {
  const { email, organizationId, invitedBy } = data;

  // Check if the inviter is admin or owner
  const inviterMembership = await prisma.organizationMember.findFirst({
    where: {
      organizationId,
      userId: invitedBy,
      role: { in: ['owner', 'admin'] },
    },
  });

  if (!inviterMembership) {
    throw new Error('Only owners and admins can invite members');
  }

  // Check if user already exists
  const existingUser = await prisma.user.findUnique({
    where: { email },
  });

  // Check if already a member
  if (existingUser) {
    const existingMembership = await prisma.organizationMember.findFirst({
      where: {
        organizationId,
        userId: existingUser.id,
      },
    });

    if (existingMembership) {
      throw new Error('User is already a member of this organization');
    }
  }

  // Check for pending invitation
  const existingInvitation = await prisma.invitation.findFirst({
    where: {
      email,
      organizationId,
      status: 'pending',
    },
  });

  if (existingInvitation) {
    throw new Error('An invitation is already pending for this email');
  }

  // Create invitation with 7 days expiry
  const token = nanoid(32);
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  const invitation = await prisma.invitation.create({
    data: {
      email,
      organizationId,
      invitedBy,
      token,
      expiresAt,
    },
  });

  return {
    id: invitation.id,
    email: invitation.email,
    token: invitation.token,
    expiresAt: invitation.expiresAt,
  };
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

/**
 * Get pending invitations for an organization
 */
export async function getPendingInvitations(organizationId: string, userId: string) {
  // Check if user is member
  const membership = await prisma.organizationMember.findFirst({
    where: {
      organizationId,
      userId,
    },
  });

  if (!membership) {
    throw new Error('Access denied');
  }

  return prisma.invitation.findMany({
    where: {
      organizationId,
      status: 'pending',
    },
    orderBy: { createdAt: 'desc' },
  });
}

/**
 * Update member role
 */
export async function updateMemberRole(
  organizationId: string,
  targetUserId: string,
  newRole: string,
  requesterId: string
) {
  // Check if requester is owner
  const requesterMembership = await prisma.organizationMember.findFirst({
    where: {
      organizationId,
      userId: requesterId,
      role: 'owner',
    },
  });

  if (!requesterMembership) {
    throw new Error('Only owners can update member roles');
  }

  // Prevent changing owner's role
  const targetMembership = await prisma.organizationMember.findFirst({
    where: {
      organizationId,
      userId: targetUserId,
    },
  });

  if (!targetMembership) {
    throw new Error('Member not found');
  }

  if (targetMembership.role === 'owner') {
    throw new Error('Cannot change owner role');
  }

  await prisma.organizationMember.update({
    where: { id: targetMembership.id },
    data: { role: newRole },
  });

  return { success: true };
}

/**
 * Remove a member from organization
 */
export async function removeMember(
  organizationId: string,
  targetUserId: string,
  requesterId: string
) {
  // Check if requester is admin or owner
  const requesterMembership = await prisma.organizationMember.findFirst({
    where: {
      organizationId,
      userId: requesterId,
      role: { in: ['owner', 'admin'] },
    },
  });

  if (!requesterMembership) {
    throw new Error('Only owners and admins can remove members');
  }

  const targetMembership = await prisma.organizationMember.findFirst({
    where: {
      organizationId,
      userId: targetUserId,
    },
  });

  if (!targetMembership) {
    throw new Error('Member not found');
  }

  // Prevent removing owner
  if (targetMembership.role === 'owner') {
    throw new Error('Cannot remove the owner');
  }

  // Prevent admins from removing other admins
  if (requesterMembership.role === 'admin' && targetMembership.role === 'admin') {
    throw new Error('Admins cannot remove other admins');
  }

  await prisma.organizationMember.delete({
    where: { id: targetMembership.id },
  });

  return { success: true };
}
