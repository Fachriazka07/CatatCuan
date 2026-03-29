import { NextRequest } from 'next/server';

import {
  jsonError,
  jsonSuccess,
} from '@/lib/mobile-api';
import {
  processDailyReminders,
  processDueDateReminders,
  processLowStockAlerts,
  sendPushNotificationToUser,
} from '@/lib/notification-service';
import { createClient } from '@/lib/supabase/server';

export const runtime = 'nodejs';

type ManualPushBody = {
  type: 'manual_push';
  userId?: string;
  warungId?: string;
  title?: string;
  body?: string;
};

type DueDateBody = {
  type: 'due_date';
  asOfDate?: string;
  lookaheadDays?: number;
};

type LowStockBody = {
  type: 'low_stock';
  asOfDate?: string;
  fallbackThreshold?: number;
};

type DailyReminderBody = {
  type: 'daily_reminder';
  asOfDate?: string;
  timezone?: string;
};

type NotificationTestBody =
  | ManualPushBody
  | DueDateBody
  | LowStockBody
  | DailyReminderBody;

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return jsonError('Unauthorized', 401);
    }

    const body = (await request.json()) as NotificationTestBody;

    switch (body.type) {
      case 'manual_push': {
        const userId = body.userId?.trim();
        const title = body.title?.trim();
        const messageBody = body.body?.trim();

        if (!userId || !title || !messageBody) {
          return jsonError('User ID, judul, dan isi notifikasi wajib diisi');
        }

        const result = await sendPushNotificationToUser({
          userId,
          warungId: body.warungId?.trim(),
          title,
          body: messageBody,
          notificationType: 'manual_test',
          data: {
            screen: 'home',
            source: 'admin_config',
          },
        });

        return jsonSuccess({
          message: result.success
            ? 'Push notification manual berhasil diproses'
            : 'Push notification manual gagal diproses',
          result,
        });
      }

      case 'due_date': {
        const result = await processDueDateReminders({
          asOfDate: body.asOfDate?.trim(),
          lookaheadDays:
            typeof body.lookaheadDays === 'number' ? body.lookaheadDays : 1,
        });

        return jsonSuccess({
          message: 'Reminder hutang jatuh tempo berhasil diproses',
          result,
        });
      }

      case 'low_stock': {
        const result = await processLowStockAlerts({
          asOfDate: body.asOfDate?.trim(),
          fallbackThreshold:
            typeof body.fallbackThreshold === 'number'
              ? body.fallbackThreshold
              : 3,
        });

        return jsonSuccess({
          message: 'Alert stok menipis / habis berhasil diproses',
          result,
        });
      }

      case 'daily_reminder': {
        const result = await processDailyReminders({
          asOfDate: body.asOfDate?.trim(),
          timezone: body.timezone?.trim() || 'Asia/Jakarta',
        });

        return jsonSuccess({
          message: 'Pengingat catat hari ini berhasil diproses',
          result,
        });
      }

      default:
        return jsonError('Jenis test notifikasi tidak dikenali');
    }
  } catch (error) {
    console.error('[api/admin/notification-tests][POST]', error);
    return jsonError('Terjadi kesalahan saat memproses test notifikasi', 500);
  }
}
