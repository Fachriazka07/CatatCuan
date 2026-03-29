CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public."MOBILE_DEVICE_TOKENS" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL REFERENCES public."USERS"("id") ON DELETE CASCADE,
  "device_token" TEXT NOT NULL UNIQUE,
  "platform" TEXT NOT NULL,
  "device_label" TEXT,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "last_seen_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "last_error" TEXT,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public."MOBILE_DEVICE_TOKENS" IS 'Stores Firebase Cloud Messaging tokens for each logged-in mobile device.';

CREATE TABLE IF NOT EXISTS public."USER_NOTIFICATION_PREFERENCES" (
  "user_id" UUID PRIMARY KEY REFERENCES public."USERS"("id") ON DELETE CASCADE,
  "push_enabled" BOOLEAN NOT NULL DEFAULT true,
  "sms_enabled" BOOLEAN NOT NULL DEFAULT true,
  "due_date_reminder" BOOLEAN NOT NULL DEFAULT true,
  "low_stock_alert" BOOLEAN NOT NULL DEFAULT true,
  "daily_reminder" BOOLEAN NOT NULL DEFAULT false,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public."USER_NOTIFICATION_PREFERENCES" IS 'Server-side copy of notification preferences so backend jobs can respect user settings.';

CREATE TABLE IF NOT EXISTS public."PASSWORD_RESET_OTPS" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL REFERENCES public."USERS"("id") ON DELETE CASCADE,
  "phone_number" TEXT NOT NULL,
  "code_hash" TEXT NOT NULL,
  "channel" TEXT NOT NULL DEFAULT 'sms',
  "expires_at" TIMESTAMPTZ NOT NULL,
  "used_at" TIMESTAMPTZ,
  "attempt_count" INT NOT NULL DEFAULT 0,
  "sent_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public."PASSWORD_RESET_OTPS" IS 'Stores one-time password reset codes sent to users.';

CREATE TABLE IF NOT EXISTS public."NOTIFICATION_LOGS" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "user_id" UUID REFERENCES public."USERS"("id") ON DELETE SET NULL,
  "warung_id" UUID REFERENCES public."WARUNG"("id") ON DELETE SET NULL,
  "channel" TEXT NOT NULL,
  "notification_type" TEXT NOT NULL,
  "title" TEXT,
  "body" TEXT,
  "payload" JSONB,
  "provider_message_id" TEXT,
  "status" TEXT NOT NULL DEFAULT 'queued',
  "error_message" TEXT,
  "sent_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public."NOTIFICATION_LOGS" IS 'Outbound push/SMS notification audit log.';

CREATE INDEX IF NOT EXISTS idx_mobile_device_tokens_user
  ON public."MOBILE_DEVICE_TOKENS"("user_id", "is_active");

CREATE INDEX IF NOT EXISTS idx_password_reset_otps_user
  ON public."PASSWORD_RESET_OTPS"("user_id", "created_at" DESC);

CREATE INDEX IF NOT EXISTS idx_password_reset_otps_phone
  ON public."PASSWORD_RESET_OTPS"("phone_number", "created_at" DESC);

CREATE INDEX IF NOT EXISTS idx_notification_logs_user
  ON public."NOTIFICATION_LOGS"("user_id", "created_at" DESC);

CREATE INDEX IF NOT EXISTS idx_notification_logs_channel_status
  ON public."NOTIFICATION_LOGS"("channel", "status", "created_at" DESC);
