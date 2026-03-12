import { Router, Request, Response } from 'express';
import { z } from 'zod';
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
router.post('/', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = createCategorySchema.parse(req.body);

    const category = await createCategory(body);

    res.status(201).json({ success: true, data: category });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /categories - List categories
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const organizationId = String(req.query.organizationId || '');

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const categories = await getCategories(organizationId);

    res.json({ success: true, data: categories });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * GET /categories/:id - Get category by ID
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const category = await getCategoryById(id as string);

    if (!category) {
      return res.status(404).json({ success: false, error: 'Category not found' });
    }

    res.json({ success: true, data: category });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * PUT /categories/:id - Update category
 */
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const body = updateCategorySchema.parse(req.body);

    const category = await updateCategory(id as string, body);

    res.json({ success: true, data: category });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

/**
 * DELETE /categories/:id - Delete category
 */
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id'] || '');
    const { id } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    await deleteCategory(id as string);

    res.json({ success: true, message: 'Category deleted' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({ success: false, error: message });
  }
});

export default router;
