import { Router, Request, Response } from 'express';
import { z } from 'zod';
import {
  listAudits,
  getAuditById,
  createAudit,
  updateAuditStatus,
  deleteAudit,
  getAuditStats,
} from './audit.service';

const router = Router();

const createAuditSchema = z.object({
  title: z.string().min(1),
  description: z.string().optional(),
  templateId: z.string().min(1),
  organizationId: z.string().min(1),
});

const updateStatusSchema = z.object({
  status: z.enum(['draft', 'in_progress', 'completed']),
});

/**
 * GET /audits - List audits with pagination and filters
 * Query params: limit, offset, status, minScore, maxScore, search, sortBy, sortOrder
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const result = await listAudits({
      userId,
      limit: Number(req.query.limit) || 20,
      offset: Number(req.query.offset) || 0,
      status: req.query.status as 'draft' | 'in_progress' | 'completed' | undefined,
      minScore: req.query.minScore ? Number(req.query.minScore) : undefined,
      maxScore: req.query.maxScore ? Number(req.query.maxScore) : undefined,
      search: req.query.search as string | undefined,
      sortBy: req.query.sortBy as 'createdAt' | 'updatedAt' | 'score' | 'title' | undefined,
      sortOrder: req.query.sortOrder as 'asc' | 'desc' | undefined,
    });

    res.json({
      success: true,
      data: result.data,
      pagination: result.pagination,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /audits/stats - Get audit statistics for user
 */
router.get('/stats', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const stats = await getAuditStats(userId);
    
    res.json({ success: true, data: stats });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /audits/:id - Get single audit by ID
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params as { id: string };
    
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const audit = await getAuditById(id, userId);
    
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
 * POST /audits - Create new audit
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = createAuditSchema.parse(req.body);
    
    const audit = await createAudit({
      title: body.title,
      description: body.description,
      templateId: body.templateId,
      organizationId: body.organizationId,
      userId,
    });

    res.status(201).json({ success: true, data: audit });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * PATCH /audits/:id/status - Update audit status
 */
router.patch('/:id/status', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params as { id: string };
    
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = updateStatusSchema.parse(req.body);
    
    await updateAuditStatus(id, userId, body.status);

    res.json({ success: true, message: 'Status updated' });
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
    const { id } = req.params as { id: string };
    
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    await deleteAudit(id, userId);

    res.json({ success: true, message: 'Audit deleted' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

export default router;
