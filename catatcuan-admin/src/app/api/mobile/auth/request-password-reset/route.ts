import {
  hasValidMobileApiKey,
  jsonError,
  jsonSuccess,
} from '@/lib/mobile-api';
import { requestPasswordReset } from '@/lib/password-reset-service';
import { NextRequest } from 'next/server';

export const runtime = 'nodejs';

type RequestPasswordResetBody = {
  phoneNumber?: string;
};

export async function POST(request: NextRequest) {
  try {
    if (!hasValidMobileApiKey(request)) {
      return jsonError('Unauthorized', 401);
    }

    const body = (await request.json()) as RequestPasswordResetBody;
    const phoneNumber = body.phoneNumber?.trim();

    if (!phoneNumber) {
      return jsonError('phoneNumber wajib diisi');
    }

    const result = await requestPasswordReset(phoneNumber);

    if (!result.success) {
      return jsonError(result.error ?? 'Gagal memproses reset password');
    }

    return jsonSuccess({
      message:
        'Jika nomor terdaftar, kode OTP reset password sudah diproses untuk dikirim.',
      userFound: result.userFound ?? false,
    });
  } catch (error) {
    console.error('[api/mobile/auth/request-password-reset][POST]', error);
    return jsonError('Terjadi kesalahan saat meminta OTP reset password', 500);
  }
}
