import { randomInt } from 'crypto';
import { NextRequest, NextResponse } from 'next/server';

const MOBILE_API_KEY_HEADER = 'x-mobile-api-key';
const DISPATCH_SECRET_HEADER = 'x-dispatch-secret';

export function normalizePhoneNumber(input: string): string | null {
  const digitsOnly = input.replace(/[^0-9]/g, '');

  if (!digitsOnly) {
    return null;
  }

  if (digitsOnly.startsWith('08')) {
    return `62${digitsOnly.slice(1)}`;
  }

  if (!digitsOnly.startsWith('628')) {
    return null;
  }

  if (digitsOnly.length < 10 || digitsOnly.length > 14) {
    return null;
  }

  return digitsOnly;
}

export function generateOtpCode() {
  return randomInt(100000, 1000000).toString();
}

export function jsonError(message: string, status = 400) {
  return NextResponse.json(
    {
      success: false,
      error: message,
    },
    { status },
  );
}

export function jsonSuccess(payload: Record<string, unknown>, status = 200) {
  return NextResponse.json(
    {
      success: true,
      ...payload,
    },
    { status },
  );
}

export function hasValidMobileApiKey(request: NextRequest) {
  const expected = process.env.MOBILE_BACKEND_API_KEY;

  if (!expected) {
    throw new Error('MOBILE_BACKEND_API_KEY is not configured');
  }

  return request.headers.get(MOBILE_API_KEY_HEADER) === expected;
}

export function hasValidDispatchSecret(request: NextRequest) {
  const expected = process.env.NOTIFICATION_DISPATCH_SECRET;

  if (!expected) {
    throw new Error('NOTIFICATION_DISPATCH_SECRET is not configured');
  }

  return request.headers.get(DISPATCH_SECRET_HEADER) === expected;
}
