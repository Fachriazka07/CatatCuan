type SendSmsArgs = {
  to: string;
  message: string;
  metadata?: Record<string, unknown>;
};

type SendSmsResult = {
  success: boolean;
  provider: string;
  messageId?: string;
  raw?: unknown;
  error?: string;
};

export function getSmsProviderMode() {
  return process.env.SMS_PROVIDER_MODE ?? 'log';
}

export async function sendSms({
  to,
  message,
  metadata,
}: SendSmsArgs): Promise<SendSmsResult> {
  const mode = getSmsProviderMode();

  if (mode === 'log') {
    console.info('[sms-provider:log]', {
      to,
      message,
      metadata,
    });

    return {
      success: true,
      provider: 'log',
      messageId: `log-${Date.now()}`,
    };
  }

  if (mode !== 'webhook') {
    return {
      success: false,
      provider: mode,
      error: `Unsupported SMS_PROVIDER_MODE: ${mode}`,
    };
  }

  const webhookUrl = process.env.SMS_PROVIDER_WEBHOOK_URL;

  if (!webhookUrl) {
    return {
      success: false,
      provider: 'webhook',
      error: 'SMS_PROVIDER_WEBHOOK_URL is not configured',
    };
  }

  const authToken = process.env.SMS_PROVIDER_AUTH_TOKEN;
  const sender = process.env.SMS_PROVIDER_SENDER;

  const response = await fetch(webhookUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(authToken ? { Authorization: `Bearer ${authToken}` } : {}),
    },
    body: JSON.stringify({
      to,
      message,
      sender,
      metadata,
    }),
    cache: 'no-store',
  });

  const rawText = await response.text();
  let raw: unknown = rawText;

  try {
    raw = JSON.parse(rawText);
  } catch {
    raw = rawText;
  }

  if (!response.ok) {
    return {
      success: false,
      provider: 'webhook',
      raw,
      error: `SMS webhook failed with status ${response.status}`,
    };
  }

  const payload =
    raw && typeof raw === 'object' ? (raw as Record<string, unknown>) : null;

  return {
    success: true,
    provider: 'webhook',
    raw,
    messageId:
      typeof payload?.messageId === 'string'
        ? payload.messageId
        : `webhook-${Date.now()}`,
  };
}
