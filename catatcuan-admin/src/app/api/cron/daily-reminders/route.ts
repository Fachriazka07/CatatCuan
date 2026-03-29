import { hasValidDispatchSecret, jsonError, jsonSuccess } from '@/lib/mobile-api';
import {
  processDueDateReminders,
  processLowStockAlerts,
} from '@/lib/notification-service';
import { NextRequest } from 'next/server';

export const runtime = 'nodejs';

function isAuthorizedCronRequest(request: NextRequest) {
  const userAgent = request.headers.get('user-agent') ?? '';

  return userAgent.includes('vercel-cron/1.0') || hasValidDispatchSecret(request);
}

export async function GET(request: NextRequest) {
  try {
    if (!isAuthorizedCronRequest(request)) {
      return jsonError('Unauthorized', 401);
    }

    const asOfDate = new Date().toISOString().slice(0, 10);

    const [dueDateReminders, lowStockAlerts] = await Promise.all([
      processDueDateReminders({
        asOfDate,
        lookaheadDays: 1,
      }),
      processLowStockAlerts({
        asOfDate,
        fallbackThreshold: 3,
      }),
    ]);

    return jsonSuccess({
      message: 'Daily reminders berhasil diproses',
      result: {
        asOfDate,
        dueDateReminders,
        lowStockAlerts,
      },
    });
  } catch (error) {
    console.error('[api/cron/daily-reminders][GET]', error);
    return jsonError('Terjadi kesalahan saat memproses daily reminders', 500);
  }
}
