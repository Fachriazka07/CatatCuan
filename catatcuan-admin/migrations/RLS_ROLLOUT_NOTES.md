# RLS Rollout Notes

## Phase 1: Safe Now

Apply [phase1_enable_rls_admin_and_master_tables.sql](/d:/Fachri/WORKSPACES/CatatCuan/catatcuan-admin/migrations/phase1_enable_rls_admin_and_master_tables.sql) first.

This phase is safe because:
- `ADMIN_USERS`, `APP_CONFIG`, and `SYSTEM_LOGS` are admin-facing tables.
- `MASTER_KATEGORI_PRODUK`, `MASTER_SATUAN`, and `MASTER_KATEGORI_PENGELUARAN` can keep public read access for mobile onboarding/cache sync.

## Admin Auth Assumption

This phase now assumes admin accounts live in Supabase Auth, not in `ADMIN_USERS`.

Set this on each admin user in Supabase Auth:

- `app_metadata.role = "admin"` or
- `app_metadata.role = "superadmin"`

`is_admin_user()` reads that claim from `auth.jwt()`.

Example expected claim shape:

```json
{
  "app_metadata": {
    "role": "superadmin"
  }
}
```

## Why Core Tables Are Still Blocked

The mobile app currently uses custom auth:
- register writes directly to `public.USERS`
- login reads `public.USERS` with phone + password
- session is stored locally, not with Supabase Auth end-user tokens

Because of that, strict RLS on these tables will break the mobile app:
- `USERS`
- `WARUNG`
- `PRODUK`
- `KATEGORI_PRODUK`
- `SATUAN_PRODUK`
- `KATEGORI_PENGELUARAN`
- `PELANGGAN`
- `PENJUALAN`
- `PENJUALAN_ITEM`
- `PENGELUARAN`
- `HUTANG`
- `PEMBAYARAN_HUTANG`
- `BUKU_KAS`
- `LAPORAN_HARIAN`

## Recommended Next Step

Pick one of these before enabling strict RLS on core tables:

1. Migrate mobile users to real Supabase Auth and use `auth.uid()` based policies.
2. Move mobile data access to server-side APIs / Edge Functions that use `service_role`.

## Important

Do not enable strict RLS on core business tables yet unless you are ready to refactor mobile auth.

Also, do not run phase 1 before your admin Auth users already have `app_metadata.role` set correctly, or admin access will be denied by RLS.
