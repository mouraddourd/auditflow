import { Router, Request, Response } from 'express';
import { z } from 'zod';
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
router.post('/', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = createAuditSchema.parse(req.body);

    const audit = await createAudit({
      ...body,
      userId,
    });

    res.status(201).json({ success: true, data: audit });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /audits - List audits
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const organizationId = String(req.query.organizationId || '');
    const status = req.query.status as string | undefined;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const audits = await getAudits(organizationId, userId, status);

    res.json({ success: true, data: audits });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /audits/:id - Get audit by ID
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const audit = await getAuditById(id as string);

    if (!audit) {
      return res.status(404).json({ success: false, error: 'Audit not found' });
    }

    res.json({ success: true, data: audit });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * PATCH /audits/:id - Update audit
 */
router.patch('/:id', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = updateAuditSchema.parse(req.body);

    const updateData: any = { ...body };
    if (body.startedAt) updateData.startedAt = new Date(body.startedAt);
    if (body.completedAt) updateData.completedAt = new Date(body.completedAt);

    const audit = await updateAudit(id as string, updateData);

    res.json({ success: true, data: audit });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * PUT /audits/:id/answers - Save answers (batch)
 */
router.put('/:id/answers', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = saveAnswersSchema.parse(req.body);

    const audit = await saveAnswers(id as string, body.answers);

    res.json({ success: true, data: audit });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * DELETE /audits/:id - Delete audit
 */
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    await deleteAudit(id as string);

    res.json({ success: true, message: 'Audit deleted' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

export default router;
