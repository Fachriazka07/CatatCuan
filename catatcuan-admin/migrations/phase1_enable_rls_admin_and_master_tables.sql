-- Phase 1 RLS rollout for CatatCuan
-- Safe to apply now for admin dashboard and public master-read tables.
--
-- Why only phase 1?
-- Mobile app still uses custom auth via public."USERS" + local session,
-- not Supabase Auth end-user tokens. Enabling strict RLS on core business
-- tables right now would break the mobile app.

CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') IN ('admin', 'superadmin');
$$;

COMMENT ON FUNCTION public.is_admin_user() IS
  'Returns true when the current Supabase Auth user has app_metadata.role = admin or superadmin.';

GRANT EXECUTE ON FUNCTION public.is_admin_user() TO anon, authenticated;

-- =====================================================================
-- ENABLE RLS
-- =====================================================================

ALTER TABLE public."ADMIN_USERS" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."APP_CONFIG" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."SYSTEM_LOGS" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."MASTER_KATEGORI_PRODUK" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."MASTER_SATUAN" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."MASTER_KATEGORI_PENGELUARAN" ENABLE ROW LEVEL SECURITY;

-- =====================================================================
-- DROP EXISTING POLICIES IF THEY ALREADY EXIST
-- =====================================================================

DROP POLICY IF EXISTS admin_users_admin_all ON public."ADMIN_USERS";
DROP POLICY IF EXISTS app_config_admin_all ON public."APP_CONFIG";
DROP POLICY IF EXISTS system_logs_admin_select ON public."SYSTEM_LOGS";
DROP POLICY IF EXISTS system_logs_admin_insert ON public."SYSTEM_LOGS";
DROP POLICY IF EXISTS master_kategori_produk_public_read ON public."MASTER_KATEGORI_PRODUK";
DROP POLICY IF EXISTS master_kategori_produk_admin_write ON public."MASTER_KATEGORI_PRODUK";
DROP POLICY IF EXISTS master_satuan_public_read ON public."MASTER_SATUAN";
DROP POLICY IF EXISTS master_satuan_admin_write ON public."MASTER_SATUAN";
DROP POLICY IF EXISTS master_kategori_pengeluaran_public_read ON public."MASTER_KATEGORI_PENGELUARAN";
DROP POLICY IF EXISTS master_kategori_pengeluaran_admin_write ON public."MASTER_KATEGORI_PENGELUARAN";

-- =====================================================================
-- ADMIN TABLES
-- =====================================================================

CREATE POLICY admin_users_admin_all
ON public."ADMIN_USERS"
FOR ALL
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

CREATE POLICY app_config_admin_all
ON public."APP_CONFIG"
FOR ALL
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

CREATE POLICY system_logs_admin_select
ON public."SYSTEM_LOGS"
FOR SELECT
USING (public.is_admin_user());

CREATE POLICY system_logs_admin_insert
ON public."SYSTEM_LOGS"
FOR INSERT
WITH CHECK (public.is_admin_user());

-- =====================================================================
-- MASTER TABLES
-- Public SELECT is intentionally allowed because mobile onboarding and cache
-- sync still read these tables without Supabase end-user auth.
-- =====================================================================

CREATE POLICY master_kategori_produk_public_read
ON public."MASTER_KATEGORI_PRODUK"
FOR SELECT
USING (true);

CREATE POLICY master_kategori_produk_admin_write
ON public."MASTER_KATEGORI_PRODUK"
FOR ALL
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

CREATE POLICY master_satuan_public_read
ON public."MASTER_SATUAN"
FOR SELECT
USING (true);

CREATE POLICY master_satuan_admin_write
ON public."MASTER_SATUAN"
FOR ALL
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

CREATE POLICY master_kategori_pengeluaran_public_read
ON public."MASTER_KATEGORI_PENGELUARAN"
FOR SELECT
USING (true);

CREATE POLICY master_kategori_pengeluaran_admin_write
ON public."MASTER_KATEGORI_PENGELUARAN"
FOR ALL
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());
