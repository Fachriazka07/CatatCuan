import {
  hasValidMobileApiKey,
  jsonError,
  jsonSuccess,
} from '@/lib/mobile-api';
import { sql } from '@/lib/server-sql';
import { NextRequest } from 'next/server';

export const runtime = 'nodejs';

type PreferenceBody = {
  userId?: string;
  pushEnabled?: boolean;
  smsEnabled?: boolean;
  dueDateReminder?: boolean;
  lowStockAlert?: boolean;
  dailyReminder?: boolean;
};

export async function POST(request: NextRequest) {
  try {
    if (!hasValidMobileApiKey(request)) {
      return jsonError('Unauthorized', 401);
    }

    const body = (await request.json()) as PreferenceBody;
    const userId = body.userId?.trim();

    if (!userId) {
      return jsonError('userId wajib diisi');
    }

    await sql`
      INSERT INTO public."USER_NOTIFICATION_PREFERENCES" (
        "user_id",
        "push_enabled",
        "sms_enabled",
        "due_date_reminder",
        "low_stock_alert",
        "daily_reminder",
        "updated_at"
      )
      VALUES (
        ${userId},
        ${body.pushEnabled ?? true},
        ${body.smsEnabled ?? true},
        ${body.dueDateReminder ?? true},
        ${body.lowStockAlert ?? true},
        ${body.dailyReminder ?? false},
        now()
      )
      ON CONFLICT ("user_id")
      DO UPDATE SET
        "push_enabled" = EXCLUDED."push_enabled",
        "sms_enabled" = EXCLUDED."sms_enabled",
        "due_date_reminder" = EXCLUDED."due_date_reminder",
        "low_stock_alert" = EXCLUDED."low_stock_alert",
        "daily_reminder" = EXCLUDED."daily_reminder",
        "updated_at" = now()
    `;

    return jsonSuccess({
      message: 'Preferensi notifikasi berhasil diperbarui',
    });
  } catch (error) {
    console.error('[api/mobile/notification-preferences][POST]', error);
    return jsonError('Terjadi kesalahan saat menyimpan preferensi', 500);
  }
}
