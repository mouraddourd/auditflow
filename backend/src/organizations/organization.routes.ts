import { Router, Request, Response } from 'express';
import { z } from 'zod';
import {
  createOrganization,
  getUserOrganizations,
  acceptInvitation,
  createInvitation,
  getInvitationInfo,
  getOrganizationInvitations,
  deleteInvitation,
} from './organization.service';

const router = Router();

const createOrgSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').max(100),
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

    // Return organization with userRole
    res.status(201).json({
      success: true,
      data: {
        ...organization,
        userRole: 'owner',
      },
    });
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

const createInvitationSchema = z.object({
  email: z.string().email('Invalid email address'),
});

/**
 * POST /organizations/:id/invitations - Create an invitation
 */
router.post('/:id/invitations', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id: organizationId } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = createInvitationSchema.parse(req.body);

    const invitation = await createInvitation({
      organizationId: organizationId as string,
      email: body.email,
      invitedBy: userId,
    });

    res.status(201).json({ success: true, data: invitation });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /organizations/:id/invitations - List invitations (admin only)
 */
router.get('/:id/invitations', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id: organizationId } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const invitations = await getOrganizationInvitations(
      organizationId as string,
      userId,
    );

    res.json({ success: true, data: invitations });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /invitations/:token/info - Get invitation info (public, no auth)
 */
router.get('/invitations/:token/info', async (req: Request, res: Response) => {
  try {
    const { token } = req.params as { token: string };

    const info = await getInvitationInfo(token);

    res.json({ success: true, data: info });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * DELETE /invitations/:id - Cancel an invitation
 */
router.delete('/invitations/:id', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id: invitationId } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    await deleteInvitation(invitationId as string, userId);

    res.json({ success: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

export default router;
