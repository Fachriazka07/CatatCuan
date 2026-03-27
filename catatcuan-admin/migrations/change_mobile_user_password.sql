CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE OR REPLACE FUNCTION public.change_mobile_user_password(
  p_user_id UUID,
  p_current_password TEXT,
  p_new_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  matched_user public."USERS"%ROWTYPE;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'USER_REQUIRED';
  END IF;

  IF coalesce(trim(p_current_password), '') = '' THEN
    RAISE EXCEPTION 'CURRENT_PASSWORD_REQUIRED';
  END IF;

  IF coalesce(trim(p_new_password), '') = '' THEN
    RAISE EXCEPTION 'NEW_PASSWORD_REQUIRED';
  END IF;

  IF length(p_new_password) < 6 THEN
    RAISE EXCEPTION 'PASSWORD_TOO_SHORT';
  END IF;

  SELECT *
  INTO matched_user
  FROM public."USERS"
  WHERE "id" = p_user_id
    AND coalesce("password_hash", '') <> ''
    AND "password_hash" = extensions.crypt(p_current_password, "password_hash")
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'CURRENT_PASSWORD_INVALID';
  END IF;

  UPDATE public."USERS"
  SET
    "password_hash" = extensions.crypt(p_new_password, extensions.gen_salt('bf')),
    "updated_at" = now()
  WHERE "id" = matched_user.id
  RETURNING * INTO matched_user;

  RETURN jsonb_build_object(
    'success', true,
    'id', matched_user.id,
    'updated_at', matched_user.updated_at
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.change_mobile_user_password(UUID, TEXT, TEXT) TO anon, authenticated;
