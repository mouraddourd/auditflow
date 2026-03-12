import { Router, Request, Response } from 'express';
import { z } from 'zod';
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
router.post('/', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = createTemplateSchema.parse(req.body);

    const template = await createTemplate({
      ...body,
      userId,
    });

    res.status(201).json({ success: true, data: template });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /templates - List templates
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const organizationId = String(req.query.organizationId || '');

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const templates = await getTemplates(organizationId, userId);

    res.json({ success: true, data: templates });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /templates/:id - Get template by ID
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const template = await getTemplateById(id as string);

    if (!template) {
      return res.status(404).json({ success: false, error: 'Template not found' });
    }

    res.json({ success: true, data: template });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * PUT /templates/:id - Update template
 */
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = updateTemplateSchema.parse(req.body);

    const template = await updateTemplate(id as string, body);

    res.json({ success: true, data: template });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * DELETE /templates/:id - Delete template
 */
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    await deleteTemplate(id as string);

    res.json({ success: true, message: 'Template deleted' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

export default router;
