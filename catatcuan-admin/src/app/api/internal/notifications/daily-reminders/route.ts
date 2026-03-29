import {
  hasValidDispatchSecret,
  jsonError,
  jsonSuccess,
} from '@/lib/mobile-api';
import { processDailyReminders } from '@/lib/notification-service';
import { NextRequest } from 'next/server';

export const runtime = 'nodejs';

type DailyRemindersBody = {
  asOfDate?: string;
  timezone?: string;
};

export async function POST(request: NextRequest) {
  try {
    if (!hasValidDispatchSecret(request)) {
      return jsonError('Unauthorized', 401);
    }

    const body = (await request.json().catch(() => ({}))) as DailyRemindersBody;

    const result = await processDailyReminders({
      asOfDate: body.asOfDate?.trim(),
      timezone: body.timezone?.trim(),
    });

    return jsonSuccess({
      message: 'Pengingat catat hari ini berhasil diproses',
      result,
    });
  } catch (error) {
    console.error('[api/internal/notifications/daily-reminders][POST]', error);
    return jsonError(
      'Terjadi kesalahan saat memproses pengingat catat hari ini',
      500,
    );
  }
}
