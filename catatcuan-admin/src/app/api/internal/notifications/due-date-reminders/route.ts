import {
  hasValidDispatchSecret,
  jsonError,
  jsonSuccess,
} from '@/lib/mobile-api';
import { processDueDateReminders } from '@/lib/notification-service';
import { NextRequest } from 'next/server';

export const runtime = 'nodejs';

type DueDateReminderBody = {
  asOfDate?: string;
  lookaheadDays?: number;
};

export async function POST(request: NextRequest) {
  try {
    if (!hasValidDispatchSecret(request)) {
      return jsonError('Unauthorized', 401);
    }

    const body = (await request.json().catch(() => ({}))) as DueDateReminderBody;

    const result = await processDueDateReminders({
      asOfDate: body.asOfDate?.trim(),
      lookaheadDays:
        typeof body.lookaheadDays === 'number' ? body.lookaheadDays : 1,
    });

    return jsonSuccess({
      message: 'Reminder hutang jatuh tempo berhasil diproses',
      result,
    });
  } catch (error) {
    console.error(
      '[api/internal/notifications/due-date-reminders][POST]',
      error,
    );
    return jsonError(
      'Terjadi kesalahan saat memproses reminder hutang jatuh tempo',
      500,
    );
  }
}
