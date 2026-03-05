import admin from 'firebase-admin';

// Initialize Firebase Admin SDK
// Requires FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL in .env
const getFirebaseApp = () => {
  // Skip initialization if Firebase credentials are not configured
  if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_PRIVATE_KEY) {
    console.log('Firebase Admin SDK not configured - notifications disabled');
    return null;
  }

  if (admin.apps.length === 0) {
    try {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        }),
      });
      console.log('Firebase Admin SDK initialized successfully');
    } catch (error) {
      console.error('Failed to initialize Firebase Admin SDK:', error);
      return null;
    }
  }
  return admin;
};

export const firebaseApp = getFirebaseApp();

// Safe messaging accessor
const getMessaging = () => {
  if (!firebaseApp) {
    throw new Error('Firebase Admin SDK not initialized');
  }
  return admin.messaging();
};

export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface SendNotificationResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

/**
 * Send notification to a single device token
 */
export async function sendToDevice(
  token: string,
  notification: NotificationPayload
): Promise<SendNotificationResult> {
  try {
    const message = {
      token,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
      webpush: {
        headers: {
          Urgency: 'high',
        },
        notification: {
          icon: '/icons/icon-192x192.png',
          badge: '/icons/badge-72x72.png',
        },
      },
    };

    const messageId = await getMessaging().send(message);
    return { success: true, messageId };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.error('Firebase send error:', errorMessage);
    return { success: false, error: errorMessage };
  }
}

/**
 * Send notification to multiple device tokens
 */
export async function sendToDevices(
  tokens: string[],
  notification: NotificationPayload
): Promise<{ results: SendNotificationResult[]; invalidTokens: string[] }> {
  const results: SendNotificationResult[] = [];
  const invalidTokens: string[] = [];

  // Process in batches of 500 (Firebase limit)
  const batchSize = 500;
  
  for (let i = 0; i < tokens.length; i += batchSize) {
    const batch = tokens.slice(i, i + batchSize);
    
    const message = {
      tokens: batch,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
    };

    try {
      const response = await getMessaging().sendEachForMulticast(message);
      
      response.responses.forEach((resp, idx) => {
        if (resp.success) {
          results.push({ success: true, messageId: resp.messageId });
        } else {
          results.push({ success: false, error: resp.error?.message });
          // Track invalid tokens for cleanup
          const errorCode = resp.error?.code;
          if (
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered'
          ) {
            invalidTokens.push(batch[idx]);
          }
        }
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('Firebase batch send error:', errorMessage);
      batch.forEach(() => {
        results.push({ success: false, error: errorMessage });
      });
    }
  }

  return { results, invalidTokens };
}

/**
 * Subscribe tokens to a topic
 */
export async function subscribeToTopic(
  tokens: string[],
  topic: string
): Promise<{ success: boolean; error?: string }> {
  if (!firebaseApp) {
    return { success: false, error: 'Firebase Admin SDK not initialized' };
  }
  try {
    await getMessaging().subscribeToTopic(tokens, topic);
    return { success: true };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return { success: false, error: errorMessage };
  }
}

/**
 * Send notification to a topic
 */
export async function sendToTopic(
  topic: string,
  notification: NotificationPayload
): Promise<SendNotificationResult> {
  if (!firebaseApp) {
    return { success: false, error: 'Firebase Admin SDK not initialized' };
  }
  try {
    const message = {
      topic,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
    };

    const messageId = await getMessaging().send(message);
    return { success: true, messageId };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return { success: false, error: errorMessage };
  }
}
