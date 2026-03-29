import {
  hasValidDispatchSecret,
  jsonError,
  jsonSuccess,
} from '@/lib/mobile-api';
import { processLowStockAlerts } from '@/lib/notification-service';
import { NextRequest } from 'next/server';

export const runtime = 'nodejs';

type LowStockAlertsBody = {
  asOfDate?: string;
  fallbackThreshold?: number;
};

export async function POST(request: NextRequest) {
  try {
    if (!hasValidDispatchSecret(request)) {
      return jsonError('Unauthorized', 401);
    }

    const body = (await request.json().catch(() => ({}))) as LowStockAlertsBody;

    const result = await processLowStockAlerts({
      asOfDate: body.asOfDate?.trim(),
      fallbackThreshold:
        typeof body.fallbackThreshold === 'number'
          ? body.fallbackThreshold
          : 3,
    });

    return jsonSuccess({
      message: 'Alert stok menipis berhasil diproses',
      result,
    });
  } catch (error) {
    console.error('[api/internal/notifications/low-stock-alerts][POST]', error);
    return jsonError('Terjadi kesalahan saat memproses alert stok', 500);
  }
}
