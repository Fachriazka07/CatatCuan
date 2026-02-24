-- Migration: Seed MASTER_KATEGORI_PRODUK
-- Date: 2026-02-22
-- Description: Insert default master product categories with icon references
-- These are template categories that get copied to each new warung during onboarding.
-- Admin can CRUD these from the admin dashboard.

-- Clear existing data (idempotent)
DELETE FROM "MASTER_KATEGORI_PRODUK";

-- Seed master categories
INSERT INTO "MASTER_KATEGORI_PRODUK" ("nama_kategori", "icon", "sort_order", "is_active") VALUES
    ('Sembako',             'Sembako.png',             1, true),
    ('Cemilan',             'Cemilan.png',             2, true),
    ('Minuman',             'Minuman.png',             3, true),
    ('Bumbu Dapur',         'BumbuDapur.png',          4, true),
    ('Rokok',               'Rokok.png',               5, true),
    ('Obat-obatan',         'Obat.png',                6, true),
    ('Perlengkapan Mandi',  'PerlengkapanMandi.png',   7, true),
    ('Lainnya',             'Lainya.png',              8, true);
