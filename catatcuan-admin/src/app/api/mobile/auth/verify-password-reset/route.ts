import {
  hasValidMobileApiKey,
  jsonError,
  jsonSuccess,
} from '@/lib/mobile-api';
import { verifyPasswordReset } from '@/lib/password-reset-service';
import { NextRequest } from 'next/server';

export const runtime = 'nodejs';

type VerifyPasswordResetBody = {
  phoneNumber?: string;
  code?: string;
  newPassword?: string;
};

export async function POST(request: NextRequest) {
  try {
    if (!hasValidMobileApiKey(request)) {
      return jsonError('Unauthorized', 401);
    }

    const body = (await request.json()) as VerifyPasswordResetBody;
    const phoneNumber = body.phoneNumber?.trim();
    const code = body.code?.trim();
    const newPassword = body.newPassword ?? '';

    if (!phoneNumber || !code || !newPassword) {
      return jsonError('phoneNumber, code, dan newPassword wajib diisi');
    }

    const result = await verifyPasswordReset({
      phoneNumber,
      code,
      newPassword,
    });

    if (!result.success) {
      return jsonError(result.error ?? 'Gagal memverifikasi OTP');
    }

    return jsonSuccess({
      message: 'Password berhasil diubah',
    });
  } catch (error) {
    console.error('[api/mobile/auth/verify-password-reset][POST]', error);
    return jsonError('Terjadi kesalahan saat verifikasi OTP', 500);
  }
}
