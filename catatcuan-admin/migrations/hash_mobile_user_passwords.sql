-- Hash existing mobile user passwords and move mobile auth to RPC helpers.
-- Apply this before deploying the updated mobile login/register code.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

ALTER TABLE public."USERS"
ADD COLUMN IF NOT EXISTS "password_hash" TEXT;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'USERS'
      AND column_name = 'password'
  ) THEN
    EXECUTE '
      UPDATE public."USERS"
      SET "password_hash" = extensions.crypt("password", extensions.gen_salt(''bf''))
      WHERE coalesce("password", '''') <> ''''
        AND coalesce("password_hash", '''') = ''''
    ';

    EXECUTE '
      UPDATE public."USERS"
      SET "password" = NULL
      WHERE "password" IS NOT NULL
    ';
  END IF;
END $$;

UPDATE public."USERS"
SET "password_hash" = extensions.crypt("password_hash", extensions.gen_salt('bf'))
WHERE coalesce("password_hash", '') <> ''
  AND "password_hash" NOT LIKE '$2a$%'
  AND "password_hash" NOT LIKE '$2b$%'
  AND "password_hash" NOT LIKE '$2y$%';

CREATE OR REPLACE FUNCTION public.register_mobile_user(
  p_phone TEXT,
  p_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  normalized_phone TEXT := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  inserted_user public."USERS"%ROWTYPE;
BEGIN
  IF normalized_phone = '' OR coalesce(trim(p_password), '') = '' THEN
    RAISE EXCEPTION 'PHONE_AND_PASSWORD_REQUIRED';
  END IF;

  IF normalized_phone LIKE '08%' THEN
    normalized_phone := '62' || substr(normalized_phone, 2);
  END IF;

  IF normalized_phone NOT LIKE '628%' THEN
    RAISE EXCEPTION 'INVALID_PHONE_FORMAT';
  END IF;

  IF length(normalized_phone) < 10 OR length(normalized_phone) > 14 THEN
    RAISE EXCEPTION 'INVALID_PHONE_LENGTH';
  END IF;

  IF length(p_password) < 6 THEN
    RAISE EXCEPTION 'PASSWORD_TOO_SHORT';
  END IF;

  INSERT INTO public."USERS" (
    "phone_number",
    "password_hash",
    "status"
  )
  VALUES (
    normalized_phone,
    extensions.crypt(p_password, extensions.gen_salt('bf')),
    'active'
  )
  RETURNING * INTO inserted_user;

  RETURN jsonb_build_object(
    'id', inserted_user.id,
    'phone_number', inserted_user.phone_number,
    'status', inserted_user.status,
    'created_at', inserted_user.created_at
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'PHONE_ALREADY_EXISTS';
END;
$$;

CREATE OR REPLACE FUNCTION public.login_mobile_user(
  p_phone TEXT,
  p_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  normalized_phone TEXT := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  matched_user public."USERS"%ROWTYPE;
BEGIN
  IF normalized_phone LIKE '08%' THEN
    normalized_phone := '62' || substr(normalized_phone, 2);
  END IF;

  SELECT *
  INTO matched_user
  FROM public."USERS"
  WHERE "phone_number" = normalized_phone
    AND coalesce("password_hash", '') <> ''
    AND "password_hash" = extensions.crypt(p_password, "password_hash")
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  IF matched_user."status" = 'active' THEN
    UPDATE public."USERS"
    SET
      "last_login_at" = now(),
      "updated_at" = now()
    WHERE "id" = matched_user.id
    RETURNING * INTO matched_user;
  END IF;

  RETURN jsonb_build_object(
    'id', matched_user.id,
    'phone_number', matched_user.phone_number,
    'status', matched_user.status,
    'created_at', matched_user.created_at,
    'updated_at', matched_user.updated_at,
    'last_login_at', matched_user.last_login_at
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.register_mobile_user(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.login_mobile_user(TEXT, TEXT) TO anon, authenticated;
