import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { requireAuth } from '../auth/auth.middleware';
import { assertAuditAccess, assertOrgMember } from '../shared/authz';
import {
  createAudit,
  getAudits,
  getAuditById,
  updateAudit,
  saveAnswers,
  deleteAudit,
} from './audit.service';

const router = Router();

const answerSchema = z.object({
  id: z.string(),
  questionId: z.string(),
  value: z.string(),
  comment: z.string().optional(),
  score: z.number().optional(),
});

const createAuditSchema = z.object({
  id: z.string(),
  title: z.string().min(1),
  description: z.string().optional(),
  templateId: z.string(),
  organizationId: z.string(),
  status: z.string().optional(),
  score: z.number().optional(),
});

const updateAuditSchema = z.object({
  title: z.string().min(1).optional(),
  description: z.string().optional(),
  status: z.string().optional(),
  score: z.number().optional(),
  startedAt: z.string().optional(),
  completedAt: z.string().optional(),
});

const saveAnswersSchema = z.object({
  answers: z.array(answerSchema),
});

/**
 * POST /audits - Create an audit
 */
router.post('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const body = createAuditSchema.parse(req.body);

    await assertOrgMember(req.userId!, body.organizationId);

    const audit = await createAudit({
      ...body,
      userId: req.userId!,
    });

    res.status(201).json({ success: true, data: audit });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

/**
 * GET /audits - List audits
 */
router.get('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const organizationId = String(req.query.organizationId || '');
    const status = req.query.status as string | undefined;

    if (!organizationId) {
      return res.status(400).json({ success: false, error: 'organizationId is required' });
    }

    await assertOrgMember(req.userId!, organizationId);

    const audits = await getAudits(organizationId, req.userId!, status);

    res.json({ success: true, data: audits });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const statusCode = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(statusCode).json({ success: false, error: message });
  }
});

/**
 * GET /audits/:id - Get audit by ID
 */
router.get('/:id', requireAuth, async (req: Request, res: Response) => {
  try {
    const { id } = req.params as { id: string };

    const audit = await getAuditById(id);

    if (!audit) {
      return res.status(404).json({ success: false, error: 'Audit not found' });
    }

    await assertOrgMember(req.userId!, audit.organizationId);

    res.json({ success: true, data: audit });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

/**
 * PATCH /audits/:id - Update audit
 */
router.patch('/:id', requireAuth, async (req: Request, res: Response) => {
  try {
    const { id } = req.params as { id: string };

    await assertAuditAccess(req.userId!, id);

    const body = updateAuditSchema.parse(req.body);

    const updateData: any = { ...body };
    if (body.startedAt) updateData.startedAt = new Date(body.startedAt);
    if (body.completedAt) updateData.completedAt = new Date(body.completedAt);

    const audit = await updateAudit(id, updateData);

    res.json({ success: true, data: audit });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

/**
 * PUT /audits/:id/answers - Save answers (batch)
 */
router.put('/:id/answers', requireAuth, async (req: Request, res: Response) => {
  try {
    const { id } = req.params as { id: string };

    await assertAuditAccess(req.userId!, id);

    const body = saveAnswersSchema.parse(req.body);

    const audit = await saveAnswers(id, body.answers);

    res.json({ success: true, data: audit });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

/**
 * DELETE /audits/:id - Delete audit
 */
router.delete('/:id', requireAuth, async (req: Request, res: Response) => {
  try {
    const { id } = req.params as { id: string };

    await assertAuditAccess(req.userId!, id);

    await deleteAudit(id);

    res.json({ success: true, message: 'Audit deleted' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

export default router;
