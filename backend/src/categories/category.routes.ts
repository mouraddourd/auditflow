import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { requireAuth } from '../auth/auth.middleware';
import { assertCategoryAccess, assertOrgMember } from '../shared/authz';
import {
  createCategory,
  getCategories,
  getCategoryById,
  updateCategory,
  deleteCategory,
} from './category.service';

const router = Router();

const createCategorySchema = z.object({
  id: z.string(),
  name: z.string().min(1),
  description: z.string().optional(),
  color: z.string().optional(),
  organizationId: z.string(),
});

const updateCategorySchema = z.object({
  name: z.string().min(1).optional(),
  description: z.string().optional(),
  color: z.string().optional(),
});

/**
 * POST /categories - Create a category
 */
router.post('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const body = createCategorySchema.parse(req.body);

    await assertOrgMember(req.userId!, body.organizationId);

    const category = await createCategory(body);

    res.status(201).json({ success: true, data: category });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

/**
 * GET /categories - List categories
 */
router.get('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const organizationId = String(req.query.organizationId || '');
    if (!organizationId) {
      return res.status(400).json({ success: false, error: 'organizationId is required' });
    }

    await assertOrgMember(req.userId!, organizationId);

    const categories = await getCategories(organizationId);

    res.json({ success: true, data: categories });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

/**
 * GET /categories/:id - Get category by ID
 */
router.get('/:id', requireAuth, async (req: Request, res: Response) => {
  try {
    const { id } = req.params as { id: string };

    const category = await getCategoryById(id as string);

    if (!category) {
      return res.status(404).json({ success: false, error: 'Category not found' });
    }

    await assertOrgMember(req.userId!, category.organizationId);

    res.json({ success: true, data: category });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

/**
 * PUT /categories/:id - Update category
 */
router.put('/:id', requireAuth, async (req: Request, res: Response) => {
  try {
    const { id } = req.params as { id: string };

    await assertCategoryAccess(req.userId!, id);

    const body = updateCategorySchema.parse(req.body);

    const category = await updateCategory(id as string, body);

    res.json({ success: true, data: category });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

/**
 * DELETE /categories/:id - Delete category
 */
router.delete('/:id', requireAuth, async (req: Request, res: Response) => {
  try {
    const { id } = req.params as { id: string };

    await assertCategoryAccess(req.userId!, id);

    await deleteCategory(id as string);

    res.json({ success: true, message: 'Category deleted' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.toLowerCase().includes('forbidden') ? 403 : 400;
    res.status(status).json({ success: false, error: message });
  }
});

export default router;
