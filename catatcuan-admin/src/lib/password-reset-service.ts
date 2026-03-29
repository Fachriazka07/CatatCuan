import { generateOtpCode, normalizePhoneNumber } from '@/lib/mobile-api';
import { logNotification } from '@/lib/notification-service';
import { sql } from '@/lib/server-sql';
import { getSmsProviderMode, sendSms } from '@/lib/sms-provider';
import {
  checkTwilioSmsVerification,
  startTwilioSmsVerification,
} from '@/lib/twilio-verify';

type UserRow = {
  id: string;
  phone_number: string;
};

type OtpRow = {
  id: string;
  user_id: string;
  attempt_count: number;
};

export async function requestPasswordReset(phoneNumber: string) {
  const normalizedPhone = normalizePhoneNumber(phoneNumber);

  if (!normalizedPhone) {
    return {
      success: false,
      error: 'Nomor HP tidak valid',
    };
  }

  const [user] = await sql<UserRow[]>`
    SELECT "id", "phone_number"
    FROM public."USERS"
    WHERE "phone_number" = ${normalizedPhone}
    LIMIT 1
  `;

  if (!user) {
    return {
      success: true,
      userFound: false,
    };
  }

  const smsProviderMode = getSmsProviderMode();

  if (smsProviderMode === 'twilio_verify') {
    const verifyResult = await startTwilioSmsVerification(user.phone_number);

    if (!verifyResult.success) {
      await logNotification({
        userId: user.id,
        channel: 'sms',
        notificationType: 'password_reset_otp',
        body: 'OTP reset password gagal diproses oleh Twilio Verify.',
        payload: {
          provider: 'twilio_verify',
          phoneNumber: user.phone_number,
        },
        status: 'failed',
        errorMessage: verifyResult.error ?? 'Twilio Verify gagal memulai OTP',
      });

      return {
        success: false,
        error: verifyResult.error ?? 'Gagal mengirim OTP via SMS',
      };
    }

    await logNotification({
      userId: user.id,
      channel: 'sms',
      notificationType: 'password_reset_otp',
      body: 'OTP reset password diproses via Twilio Verify.',
      payload: {
        provider: 'twilio_verify',
        phoneNumber: user.phone_number,
        verificationStatus: verifyResult.status ?? 'pending',
      },
      providerMessageId: verifyResult.sid,
      status: 'sent',
      sentAt: new Date(),
    });

    return {
      success: true,
      userFound: true,
    };
  }

  await sql`
    UPDATE public."PASSWORD_RESET_OTPS"
    SET "expires_at" = now()
    WHERE "user_id" = ${user.id}
      AND "used_at" IS NULL
      AND "expires_at" > now()
  `;

  const code = generateOtpCode();
  const [otpRecord] = await sql<{ id: string }[]>`
    INSERT INTO public."PASSWORD_RESET_OTPS" (
      "user_id",
      "phone_number",
      "code_hash",
      "channel",
      "expires_at"
    )
    VALUES (
      ${user.id},
      ${user.phone_number},
      extensions.crypt(${code}, extensions.gen_salt('bf')),
      'sms',
      now() + interval '10 minutes'
    )
    RETURNING "id"
  `;

  const message = `Kode reset password CatatCuan: ${code}. Berlaku 10 menit. Jangan bagikan ke orang lain.`;
  const smsResult = await sendSms({
    to: user.phone_number,
    message,
    metadata: {
      userId: user.id,
      otpId: otpRecord.id,
      useCase: 'password_reset',
    },
  });

  if (!smsResult.success) {
    await sql`
      UPDATE public."PASSWORD_RESET_OTPS"
      SET "expires_at" = now()
      WHERE "id" = ${otpRecord.id}
    `;

    await logNotification({
      userId: user.id,
      channel: 'sms',
      notificationType: 'password_reset_otp',
      body: message,
      status: 'failed',
      errorMessage: smsResult.error ?? 'SMS provider failed',
    });

    return {
      success: false,
      error: smsResult.error ?? 'Gagal mengirim SMS',
    };
  }

  await logNotification({
    userId: user.id,
    channel: 'sms',
    notificationType: 'password_reset_otp',
    body: message,
    payload: {
      otpId: otpRecord.id,
      provider: smsResult.provider,
    },
    providerMessageId: smsResult.messageId,
    status: 'sent',
    sentAt: new Date(),
  });

  return {
    success: true,
    userFound: true,
  };
}

export async function verifyPasswordReset(params: {
  phoneNumber: string;
  code: string;
  newPassword: string;
}) {
  const normalizedPhone = normalizePhoneNumber(params.phoneNumber);

  if (!normalizedPhone) {
    return {
      success: false,
      error: 'Nomor HP tidak valid',
    };
  }

  if (!/^\d{6}$/.test(params.code)) {
    return {
      success: false,
      error: 'Kode OTP harus 6 digit',
    };
  }

  if (params.newPassword.trim().length < 6) {
    return {
      success: false,
      error: 'Password baru minimal 6 karakter',
    };
  }

  const smsProviderMode = getSmsProviderMode();

  if (smsProviderMode === 'twilio_verify') {
    const [user] = await sql<UserRow[]>`
      SELECT "id", "phone_number"
      FROM public."USERS"
      WHERE "phone_number" = ${normalizedPhone}
      LIMIT 1
    `;

    if (!user) {
      return {
        success: false,
        error: 'Nomor HP tidak ditemukan',
      };
    }

    const verifyResult = await checkTwilioSmsVerification(
      user.phone_number,
      params.code,
    );

    if (!verifyResult.success || verifyResult.status !== 'approved') {
      return {
        success: false,
        error: 'Kode OTP salah atau sudah kedaluwarsa',
      };
    }

    await sql`
      UPDATE public."USERS"
      SET
        "password_hash" = extensions.crypt(${params.newPassword}, extensions.gen_salt('bf')),
        "updated_at" = now()
      WHERE "id" = ${user.id}
    `;

    return {
      success: true,
    };
  }

  const [otp] = await sql<OtpRow[]>`
    SELECT
      "id",
      "user_id",
      "attempt_count"
    FROM public."PASSWORD_RESET_OTPS"
    WHERE "phone_number" = ${normalizedPhone}
      AND "used_at" IS NULL
      AND "expires_at" > now()
    ORDER BY "created_at" DESC
    LIMIT 1
  `;

  if (!otp) {
    return {
      success: false,
      error: 'Kode OTP tidak ditemukan atau sudah kedaluwarsa',
    };
  }

  const [matchedOtp] = await sql<{ id: string }[]>`
    SELECT "id"
    FROM public."PASSWORD_RESET_OTPS"
    WHERE "id" = ${otp.id}
      AND "used_at" IS NULL
      AND "expires_at" > now()
      AND "code_hash" = extensions.crypt(${params.code}, "code_hash")
    LIMIT 1
  `;

  if (!matchedOtp) {
    await sql`
      UPDATE public."PASSWORD_RESET_OTPS"
      SET
        "attempt_count" = "attempt_count" + 1,
        "expires_at" = CASE
          WHEN "attempt_count" + 1 >= 5 THEN now()
          ELSE "expires_at"
        END
      WHERE "id" = ${otp.id}
    `;

    return {
      success: false,
      error: 'Kode OTP salah',
    };
  }

  await sql`
    UPDATE public."USERS"
    SET
      "password_hash" = extensions.crypt(${params.newPassword}, extensions.gen_salt('bf')),
      "updated_at" = now()
    WHERE "id" = ${otp.user_id}
  `;

  await sql`
    UPDATE public."PASSWORD_RESET_OTPS"
    SET
      "used_at" = now(),
      "attempt_count" = "attempt_count" + 1
    WHERE "id" = ${otp.id}
  `;

  return {
    success: true,
  };
}
