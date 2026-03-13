import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { requireAuth } from '../auth/auth.middleware';
import {
  assertOrgMember,
  assertTemplateAccess,
} from '../shared/authz';
import {
  createTemplate,
  getTemplates,
  getTemplateById,
  updateTemplate,
  deleteTemplate,
} from './template.service';

const router = Router();

const questionSchema = z.object({
  id: z.string(),
  type: z.string(),
  text: z.string(),
  order: z.number(),
  required: z.boolean(),
  options: z.any().optional(),
});

const createTemplateSchema = z.object({
  id: z.string(),
  name: z.string().min(1),
  description: z.string().optional(),
  category: z.string().optional(),
  organizationId: z.string(),
  isPublic: z.boolean().optional(),
  questions: z.array(questionSchema),
});

const updateTemplateSchema = z.object({
  name: z.string().min(1).optional(),
  description: z.string().optional(),
  category: z.string().optional(),
  isPublic: z.boolean().optional(),
  questions: z.array(questionSchema).optional(),
});

/**
 * POST /templates - Create a template
 */
router.post('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const body = createTemplateSchema.parse(req.body);

    // Ensure caller belongs to org
    await assertOrgMember(req.userId!, body.organizationId);

    const template = await createTemplate({
      ...body,
      userId: req.userId!,
    });

    res.status(201).json({ success: true, data: template });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

/**
 * GET /templates - List templates
 */
router.get('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const organizationId = String(req.query.organizationId || '');
    if (!organizationId) {
      return res.status(400).json({ success: false, error: 'organizationId is required' });
    }

    await assertOrgMember(req.userId!, organizationId);

    const templates = await getTemplates(organizationId, req.userId!);

    res.json({ success: true, data: templates });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

/**
 * GET /templates/:id - Get template by ID
 */
router.get('/:id', requireAuth, async (req: Request, res: Response) => {
  try {
    const { id } = req.params as { id: string };

    const template = await getTemplateById(id as string);

    if (!template) {
      return res.status(404).json({ success: false, error: 'Template not found' });
    }

    await assertOrgMember(req.userId!, template.organizationId);

    res.json({ success: true, data: template });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

/**
 * PUT /templates/:id - Update template
 */
router.put('/:id', requireAuth, async (req: Request, res: Response) => {
  try {
    const { id } = req.params as { id: string };

    const body = updateTemplateSchema.parse(req.body);

    await assertTemplateAccess(req.userId!, id);

    const template = await updateTemplate(id as string, body);

    res.json({ success: true, data: template });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

/**
 * DELETE /templates/:id - Delete template
 */
router.delete('/:id', requireAuth, async (req: Request, res: Response) => {
  try {
    const { id } = req.params as { id: string };

    await assertTemplateAccess(req.userId!, id);

    await deleteTemplate(id as string);

    res.json({ success: true, message: 'Template deleted' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

export default router;
