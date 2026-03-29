const TWILIO_VERIFY_BASE_URL = 'https://verify.twilio.com/v2';

type TwilioVerifyResponse = {
  sid?: string;
  status?: string;
  to?: string;
  channel?: string;
};

type TwilioVerifyResult = {
  success: boolean;
  status?: string;
  sid?: string;
  raw?: unknown;
  error?: string;
};

function getTwilioConfig() {
  const accountSid = process.env.TWILIO_ACCOUNT_SID?.trim();
  const authToken = process.env.TWILIO_AUTH_TOKEN?.trim();
  const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID?.trim();

  if (!accountSid || !authToken || !verifyServiceSid) {
    return {
      success: false as const,
      error:
        'TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, atau TWILIO_VERIFY_SERVICE_SID belum dikonfigurasi',
    };
  }

  if (!accountSid.startsWith('AC')) {
    return {
      success: false as const,
      error: 'TWILIO_ACCOUNT_SID tidak valid. Harus diawali AC',
    };
  }

  if (!verifyServiceSid.startsWith('VA')) {
    return {
      success: false as const,
      error: 'TWILIO_VERIFY_SERVICE_SID tidak valid. Harus diawali VA',
    };
  }

  return {
    success: true as const,
    accountSid,
    authToken,
    verifyServiceSid,
  };
}

function toE164(phoneNumber: string) {
  return phoneNumber.startsWith('+') ? phoneNumber : `+${phoneNumber}`;
}

async function callTwilioVerify(
  path: string,
  params: Record<string, string>,
): Promise<TwilioVerifyResult> {
  const config = getTwilioConfig();

  if (!config.success) {
    return config;
  }

  const credentials = Buffer.from(
    `${config.accountSid}:${config.authToken}`,
  ).toString('base64');

  const response = await fetch(
    `${TWILIO_VERIFY_BASE_URL}/Services/${config.verifyServiceSid}/${path}`,
    {
      method: 'POST',
      headers: {
        Authorization: `Basic ${credentials}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams(params).toString(),
      cache: 'no-store',
    },
  );

  const rawText = await response.text();
  let raw: unknown = rawText;

  try {
    raw = JSON.parse(rawText) as TwilioVerifyResponse;
  } catch {
    raw = rawText;
  }

  if (!response.ok) {
    const payload =
      raw && typeof raw === 'object' ? (raw as Record<string, unknown>) : null;

    return {
      success: false,
      raw,
      error:
        typeof payload?.message === 'string'
          ? payload.message
          : `Twilio Verify gagal dengan status ${response.status}`,
    };
  }

  const payload =
    raw && typeof raw === 'object' ? (raw as TwilioVerifyResponse) : null;

  return {
    success: true,
    raw,
    sid: payload?.sid,
    status: payload?.status,
  };
}

export async function startTwilioSmsVerification(phoneNumber: string) {
  return callTwilioVerify('Verifications', {
    To: toE164(phoneNumber),
    Channel: 'sms',
  });
}

export async function checkTwilioSmsVerification(
  phoneNumber: string,
  code: string,
) {
  return callTwilioVerify('VerificationCheck', {
    To: toE164(phoneNumber),
    Code: code,
  });
}
