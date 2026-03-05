import { Router, Request, Response } from 'express';
import { z } from 'zod';
import {
  createOrganization,
  getUserOrganizations,
  getOrganizationById,
  inviteMember,
  acceptInvitation,
  getPendingInvitations,
  updateMemberRole,
  removeMember,
} from './organization.service';

const router = Router();

const createOrgSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').max(100),
});

const inviteMemberSchema = z.object({
  email: z.string().email('Invalid email address'),
});

const updateRoleSchema = z.object({
  role: z.enum(['admin', 'member']),
});

/**
 * POST /organizations - Create a new organization
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = createOrgSchema.parse(req.body);

    const organization = await createOrganization({
      name: body.name,
      userId,
    });

    res.status(201).json({ success: true, data: organization });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /organizations - Get user's organizations
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const organizations = await getUserOrganizations(userId);

    res.json({ success: true, data: organizations });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /organizations/:id - Get organization by ID
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params as { id: string };

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const organization = await getOrganizationById(id, userId);

    if (!organization) {
      return res.status(404).json({ success: false, error: 'Organization not found' });
    }

    res.json({ success: true, data: organization });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * POST /organizations/:id/invite - Invite a member
 */
router.post('/:id/invite', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id: organizationId } = req.params as { id: string };

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = inviteMemberSchema.parse(req.body);

    const invitation = await inviteMember({
      email: body.email,
      organizationId,
      invitedBy: userId,
    });

    res.status(201).json({ success: true, data: invitation });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /organizations/:id/invitations - Get pending invitations
 */
router.get('/:id/invitations', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id: organizationId } = req.params as { id: string };

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const invitations = await getPendingInvitations(organizationId, userId);

    res.json({ success: true, data: invitations });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * POST /organizations/join/:token - Accept invitation
 */
router.post('/join/:token', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { token } = req.params as { token: string };

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const organization = await acceptInvitation(token, userId);

    res.json({ success: true, data: organization });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * PATCH /organizations/:orgId/members/:userId/role - Update member role
 */
router.patch('/:orgId/members/:userId/role', async (req: Request, res: Response) => {
  try {
    const requesterId = String(req.headers['x-user-id'] || '');
    const { orgId, userId: targetUserId } = req.params as { orgId: string; userId: string };

    if (!requesterId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = updateRoleSchema.parse(req.body);

    await updateMemberRole(orgId, targetUserId, body.role, requesterId);

    res.json({ success: true, message: 'Role updated' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * DELETE /organizations/:orgId/members/:userId - Remove member
 */
router.delete('/:orgId/members/:userId', async (req: Request, res: Response) => {
  try {
    const requesterId = String(req.headers['x-user-id'] || '');
    const { orgId, userId: targetUserId } = req.params as { orgId: string; userId: string };

    if (!requesterId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    await removeMember(orgId, targetUserId, requesterId);

    res.json({ success: true, message: 'Member removed' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

export default router;
