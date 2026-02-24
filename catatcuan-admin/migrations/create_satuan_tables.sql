-- Migration: Create MASTER_SATUAN + SATUAN_PRODUK tables and seed data
-- Date: 2026-02-23

-- 1. Create MASTER_SATUAN table
CREATE TABLE IF NOT EXISTS "MASTER_SATUAN" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "nama_satuan" TEXT NOT NULL,
    "sort_order" INT DEFAULT 0,
    "is_active" BOOLEAN DEFAULT true,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "MASTER_SATUAN" IS 'Master list of unit measurements suggested to new users.';

-- 2. Create SATUAN_PRODUK table (user-specific, linked to master)
CREATE TABLE IF NOT EXISTS "SATUAN_PRODUK" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "nama_satuan" TEXT NOT NULL,
    "sort_order" INT DEFAULT 0,
    "master_satuan_id" UUID REFERENCES "MASTER_SATUAN"("id") ON DELETE SET NULL,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_satuan_produk_master ON "SATUAN_PRODUK"("master_satuan_id");
CREATE INDEX IF NOT EXISTS idx_satuan_produk_warung ON "SATUAN_PRODUK"("warung_id");

-- 3. Seed MASTER_SATUAN with default units
INSERT INTO "MASTER_SATUAN" ("nama_satuan", "sort_order") VALUES
    ('PCS', 0),
    ('KG', 1),
    ('GRAM', 2),
    ('LITER', 3),
    ('ML', 4),
    ('PAK', 5),
    ('DUS', 6),
    ('LUSIN', 7),
    ('BOTOL', 8),
    ('BUNGKUS', 9),
    ('SACHET', 10),
    ('KALENG', 11),
    ('RENTENG', 12),
    ('KARUNG', 13)
ON CONFLICT DO NOTHING;
