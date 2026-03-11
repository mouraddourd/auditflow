import { Router, Request, Response } from 'express';
import { AuthService, RegisterInput, LoginInput } from './auth.service';
import { requireAuth } from './auth.middleware';

const router = Router();

/**
 * POST /auth/register
 * Register a new user
 */
router.post('/register', async (req: Request, res: Response) => {
  const input: RegisterInput = req.body;

  const result = await AuthService.register(input);

  if (!result.success) {
    return res.status(400).json({
      success: false,
      error: result.error,
    });
  }

  return res.status(201).json({
    success: true,
    data: result.data,
  });
});

/**
 * POST /auth/login
 * Login an existing user
 */
router.post('/login', async (req: Request, res: Response) => {
  const input: LoginInput = req.body;

  const result = await AuthService.login(input);

  if (!result.success) {
    return res.status(401).json({
      success: false,
      error: result.error,
    });
  }

  return res.json({
    success: true,
    data: result.data,
  });
});

/**
 * GET /auth/me
 * Get current user info (requires authentication)
 */
router.get('/me', requireAuth, async (req: Request, res: Response) => {
  const user = await AuthService.getUserById(req.userId!);

  if (!user) {
    return res.status(404).json({
      success: false,
      error: 'Utilisateur non trouvé',
    });
  }

  return res.json({
    success: true,
    data: user,
  });
});

/**
 * PUT /auth/profile
 * Update current user profile (requires authentication)
 */
router.put('/profile', requireAuth, async (req: Request, res: Response) => {
  const { name, phone, avatar } = req.body;

  try {
    const updatedUser = await AuthService.updateProfile(req.userId!, {
      name,
      phone,
      avatar,
    });

    return res.json({
      success: true,
      data: updatedUser,
    });
  } catch (error) {
    console.error('Update profile error:', error);
    return res.status(500).json({
      success: false,
      error: 'Erreur lors de la mise à jour du profil',
    });
  }
});

export default router;
