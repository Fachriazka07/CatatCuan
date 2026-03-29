import {
  hasValidMobileApiKey,
  jsonError,
  jsonSuccess,
} from '@/lib/mobile-api';
import { sql } from '@/lib/server-sql';
import { NextRequest } from 'next/server';

export const runtime = 'nodejs';

type DeviceTokenBody = {
  userId?: string;
  token?: string;
  platform?: string;
  deviceLabel?: string;
};

export async function POST(request: NextRequest) {
  try {
    if (!hasValidMobileApiKey(request)) {
      return jsonError('Unauthorized', 401);
    }

    const body = (await request.json()) as DeviceTokenBody;
    const userId = body.userId?.trim();
    const token = body.token?.trim();
    const platform = body.platform?.trim().toLowerCase();
    const deviceLabel = body.deviceLabel?.trim();

    if (!userId || !token || !platform) {
      return jsonError('userId, token, dan platform wajib diisi');
    }

    await sql`
      INSERT INTO public."MOBILE_DEVICE_TOKENS" (
        "user_id",
        "device_token",
        "platform",
        "device_label",
        "is_active",
        "last_seen_at",
        "updated_at"
      )
      VALUES (
        ${userId},
        ${token},
        ${platform},
        ${deviceLabel ?? null},
        true,
        now(),
        now()
      )
      ON CONFLICT ("device_token")
      DO UPDATE SET
        "user_id" = EXCLUDED."user_id",
        "platform" = EXCLUDED."platform",
        "device_label" = EXCLUDED."device_label",
        "is_active" = true,
        "last_seen_at" = now(),
        "last_error" = NULL,
        "updated_at" = now()
    `;

    await sql`
      INSERT INTO public."USER_NOTIFICATION_PREFERENCES" (
        "user_id"
      )
      VALUES (${userId})
      ON CONFLICT ("user_id") DO NOTHING
    `;

    return jsonSuccess({
      message: 'Device token berhasil disimpan',
    });
  } catch (error) {
    console.error('[api/mobile/device-token][POST]', error);
    return jsonError('Terjadi kesalahan saat menyimpan device token', 500);
  }
}

export async function DELETE(request: NextRequest) {
  try {
    if (!hasValidMobileApiKey(request)) {
      return jsonError('Unauthorized', 401);
    }

    const body = (await request.json()) as DeviceTokenBody;
    const token = body.token?.trim();

    if (!token) {
      return jsonError('token wajib diisi');
    }

    await sql`
      UPDATE public."MOBILE_DEVICE_TOKENS"
      SET
        "is_active" = false,
        "updated_at" = now()
      WHERE "device_token" = ${token}
    `;

    return jsonSuccess({
      message: 'Device token berhasil dinonaktifkan',
    });
  } catch (error) {
    console.error('[api/mobile/device-token][DELETE]', error);
    return jsonError('Terjadi kesalahan saat menonaktifkan device token', 500);
  }
}
