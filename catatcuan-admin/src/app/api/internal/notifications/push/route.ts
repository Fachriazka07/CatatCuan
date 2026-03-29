import {
  hasValidDispatchSecret,
  jsonError,
  jsonSuccess,
} from '@/lib/mobile-api';
import { sendPushNotificationToUser } from '@/lib/notification-service';
import { NextRequest } from 'next/server';

export const runtime = 'nodejs';

type PushNotificationBody = {
  userId?: string;
  warungId?: string;
  title?: string;
  body?: string;
  notificationType?: string;
  data?: Record<string, string | number | boolean>;
};

export async function POST(request: NextRequest) {
  try {
    if (!hasValidDispatchSecret(request)) {
      return jsonError('Unauthorized', 401);
    }

    const body = (await request.json()) as PushNotificationBody;
    const userId = body.userId?.trim();
    const title = body.title?.trim();
    const messageBody = body.body?.trim();
    const notificationType = body.notificationType?.trim() ?? 'manual_test';

    if (!userId || !title || !messageBody) {
      return jsonError('userId, title, dan body wajib diisi');
    }

    const result = await sendPushNotificationToUser({
      userId,
      warungId: body.warungId?.trim(),
      title,
      body: messageBody,
      notificationType,
      data: body.data,
    });

    return jsonSuccess({
      message: result.success
        ? 'Push notification berhasil diproses'
        : 'Push notification gagal diproses',
      result,
    });
  } catch (error) {
    console.error('[api/internal/notifications/push][POST]', error);
    return jsonError('Terjadi kesalahan saat mengirim push notification', 500);
  }
}
