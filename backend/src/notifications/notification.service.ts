import { sendToDevice, sendToDevices, NotificationPayload, SendNotificationResult } from './firebase';
import prisma from '../shared/prisma';

export interface CreateNotificationData {
  userId: string;
  title: string;
  body: string;
  type: 'audit_completed' | 'audit_reminder' | 'comment' | 'system' | 'custom';
  data?: Record<string, string>;
}

export interface RegisterTokenData {
  userId: string;
  token: string;
  deviceType?: 'web' | 'android' | 'ios';
  deviceId?: string;
}

/**
 * Register or update an FCM token for a user
 */
export async function registerFcmToken(data: RegisterTokenData) {
  const existingToken = await prisma.fcmToken.findUnique({
    where: { token: data.token },
  });

  if (existingToken) {
    // Update existing token
    return prisma.fcmToken.update({
      where: { token: data.token },
      data: {
        userId: data.userId,
        deviceType: data.deviceType || 'web',
        deviceId: data.deviceId,
        lastUsed: new Date(),
        isActive: true,
      },
    });
  }

  // Create new token
  return prisma.fcmToken.create({
    data: {
      token: data.token,
      userId: data.userId,
      deviceType: data.deviceType || 'web',
      deviceId: data.deviceId,
    },
  });
}

/**
 * Unregister an FCM token
 */
export async function unregisterFcmToken(token: string) {
  return prisma.fcmToken.update({
    where: { token },
    data: { isActive: false },
  });
}

/**
 * Get all active tokens for a user
 */
export async function getUserTokens(userId: string): Promise<string[]> {
  const tokens = await prisma.fcmToken.findMany({
    where: {
      userId,
      isActive: true,
    },
    select: { token: true },
  });

  return tokens.map((t) => t.token);
}

/**
 * Clean up invalid tokens
 */
export async function cleanupInvalidTokens(invalidTokens: string[]) {
  if (invalidTokens.length === 0) return;

  await prisma.fcmToken.updateMany({
    where: {
      token: { in: invalidTokens },
    },
    data: {
      isActive: false,
    },
  });
}

/**
 * Send notification to a specific user
 */
export async function sendNotificationToUser(
  userId: string,
  notification: NotificationPayload
): Promise<{ success: boolean; results: SendNotificationResult[] }> {
  const tokens = await getUserTokens(userId);

  if (tokens.length === 0) {
    return { success: false, results: [{ success: false, error: 'No active tokens for user' }] };
  }

  const { results, invalidTokens } = await sendToDevices(tokens, notification);

  // Clean up invalid tokens
  await cleanupInvalidTokens(invalidTokens);

  // Only store notification if at least one send succeeded
  const hasSuccess = results.some((r) => r.success);
  if (hasSuccess) {
    await prisma.notification.create({
      data: {
        userId,
        title: notification.title,
        body: notification.body,
        type: 'custom',
        data: notification.data || {},
      },
    });
  }

  return { success: hasSuccess, results };
}

/**
 * Send notification to multiple users
 */
export async function sendNotificationToUsers(
  userIds: string[],
  notification: NotificationPayload
): Promise<{ success: boolean; totalSent: number }> {
  let totalSent = 0;

  for (const userId of userIds) {
    const result = await sendNotificationToUser(userId, notification);
    if (result.success) {
      totalSent++;
    }
  }

  return { success: totalSent > 0, totalSent };
}

/**
 * Send audit completion notification
 */
export async function sendAuditCompletionNotification(
  userId: string,
  auditId: string,
  auditTitle: string,
  score: number
) {
  const notification: NotificationPayload = {
    title: 'Audit terminé !',
    body: `${auditTitle} - Score: ${score}%`,
    data: {
      type: 'audit_completed',
      auditId,
      score: score.toString(),
    },
  };

  const result = await sendNotificationToUser(userId, notification);

  // Update notification type in database
  await prisma.notification.updateMany({
    where: {
      userId,
      data: { path: ['auditId'], equals: auditId },
    },
    data: { type: 'audit_completed' },
  });

  return result;
}

/**
 * Send audit reminder notification
 */
export async function sendAuditReminderNotification(
  userId: string,
  auditId: string,
  auditTitle: string
) {
  const notification: NotificationPayload = {
    title: 'Rappel d\'audit',
    body: `N'oubliez pas de compléter: ${auditTitle}`,
    data: {
      type: 'audit_reminder',
      auditId,
    },
  };

  const result = await sendNotificationToUser(userId, notification);

  // Update notification type in database
  await prisma.notification.updateMany({
    where: {
      userId,
      data: { path: ['auditId'], equals: auditId },
    },
    data: { type: 'audit_reminder' },
  });

  return result;
}

/**
 * Get notification history for a user
 */
export async function getNotificationHistory(
  userId: string,
  options: { limit?: number; offset?: number } = {}
) {
  const { limit = 20, offset = 0 } = options;

  const [notifications, total] = await Promise.all([
    prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    }),
    prisma.notification.count({
      where: { userId },
    }),
  ]);

  return {
    notifications,
    pagination: {
      total,
      limit,
      offset,
      hasMore: offset + limit < total,
    },
  };
}

/**
 * Mark notification as read
 */
export async function markNotificationAsRead(notificationId: string, userId: string) {
  return prisma.notification.updateMany({
    where: {
      id: notificationId,
      userId,
    },
    data: {
      readAt: new Date(),
    },
  });
}

/**
 * Mark all notifications as read for a user
 */
export async function markAllNotificationsAsRead(userId: string) {
  return prisma.notification.updateMany({
    where: {
      userId,
      readAt: null,
    },
    data: {
      readAt: new Date(),
    },
  });
}
