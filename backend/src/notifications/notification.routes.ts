import { Router, Request, Response } from 'express';
import { z } from 'zod';
import {
  registerFcmToken,
  unregisterFcmToken,
  sendNotificationToUser,
  getNotificationHistory,
  markNotificationAsRead,
  markAllNotificationsAsRead,
} from './notification.service';

const router = Router();

// Validation schemas
const registerTokenSchema = z.object({
  token: z.string().min(1),
  deviceType: z.enum(['web', 'android', 'ios']).optional(),
  deviceId: z.string().optional(),
});

const sendNotificationSchema = z.object({
  userId: z.string().min(1),
  title: z.string().min(1),
  body: z.string().min(1),
  data: z.record(z.string(), z.any()).optional(),
});

const paginationSchema = z.object({
  limit: z.coerce.number().min(1).max(100).default(20),
  offset: z.coerce.number().min(0).default(0),
});

/**
 * POST /notifications/register - Register FCM token
 */
router.post('/register', async (req: Request, res: Response) => {
  try {
    const userId = req.headers['x-user-id'] as string;
    
    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized: missing user ID',
      });
    }
    
    const body = registerTokenSchema.parse(req.body) as z.infer<typeof registerTokenSchema>;
    
    const result = await registerFcmToken({
      userId,
      token: body.token,
      deviceType: body.deviceType,
      deviceId: body.deviceId,
    });
    
    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({
      success: false,
      error: message,
    });
  }
});

/**
 * DELETE /notifications/unregister - Unregister FCM token
 */
router.delete('/unregister', async (req: Request, res: Response) => {
  try {
    const { token } = req.body;
    
    if (!token) {
      return res.status(400).json({
        success: false,
        error: 'Token is required',
      });
    }
    
    await unregisterFcmToken(token);
    
    res.json({
      success: true,
      message: 'Token unregistered',
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({
      success: false,
      error: message,
    });
  }
});

/**
 * POST /notifications/send - Send notification to user
 * Note: This endpoint should be restricted to authenticated users or internal services
 */
router.post('/send', async (req: Request, res: Response) => {
  try {
    // Require authentication
    const authenticatedUserId = req.headers['x-user-id'] as string;
    if (!authenticatedUserId) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized: missing user ID',
      });
    }

    const body = sendNotificationSchema.parse(req.body) as z.infer<typeof sendNotificationSchema>;
    
    const result = await sendNotificationToUser(body.userId, {
      title: body.title,
      body: body.body,
      data: body.data as Record<string, string> | undefined,
    });
    
    res.json({
      success: result.success,
      results: result.results,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({
      success: false,
      error: message,
    });
  }
});

/**
 * GET /notifications/history - Get notification history
 */
router.get('/history', async (req: Request, res: Response) => {
  try {
    const userId = req.headers['x-user-id'] as string;
    
    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized: missing user ID',
      });
    }
    
    const query = paginationSchema.parse(req.query);
    
    const result = await getNotificationHistory(userId, query);
    
    res.json({
      success: true,
      data: result.notifications,
      pagination: result.pagination,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({
      success: false,
      error: message,
    });
  }
});

/**
 * PATCH /notifications/:id/read - Mark notification as read
 */
router.patch('/:id/read', async (req: Request, res: Response) => {
  try {
    const userId = String(req.headers['x-user-id']);
    const { id } = req.params;
    
    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized: missing user ID',
      });
    }
    
    await markNotificationAsRead(String(id), userId);
    
    res.json({
      success: true,
      message: 'Notification marked as read',
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({
      success: false,
      error: message,
    });
  }
});

/**
 * PATCH /notifications/read-all - Mark all notifications as read
 */
router.patch('/read-all', async (req: Request, res: Response) => {
  try {
    const userId = req.headers['x-user-id'] as string;
    
    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized: missing user ID',
      });
    }
    
    await markAllNotificationsAsRead(userId);
    
    res.json({
      success: true,
      message: 'All notifications marked as read',
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    res.status(400).json({
      success: false,
      error: message,
    });
  }
});

export default router;
