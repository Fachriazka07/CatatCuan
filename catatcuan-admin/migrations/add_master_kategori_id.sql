-- Migration: Add master_kategori_id to KATEGORI_PRODUK
-- Date: 2026-02-22
-- Purpose: Link user categories to master categories by ID for reliable sync

-- 1. Add the FK column
ALTER TABLE "KATEGORI_PRODUK"
ADD COLUMN IF NOT EXISTS "master_kategori_id" UUID REFERENCES "MASTER_KATEGORI_PRODUK"("id") ON DELETE SET NULL;

-- 2. Create index for performance
CREATE INDEX IF NOT EXISTS idx_kategori_produk_master ON "KATEGORI_PRODUK"("master_kategori_id");

-- 3. Backfill: link existing user categories to master by matching name
UPDATE "KATEGORI_PRODUK" kp
SET "master_kategori_id" = mk."id"
FROM "MASTER_KATEGORI_PRODUK" mk
WHERE LOWER(kp."nama_kategori") = LOWER(mk."nama_kategori")
  AND kp."master_kategori_id" IS NULL;

-- 4. Clean up duplicates: keep only the newest entry per (warung_id, master_kategori_id)
DELETE FROM "KATEGORI_PRODUK"
WHERE "id" IN (
    SELECT "id" FROM (
        SELECT "id",
               ROW_NUMBER() OVER (
                   PARTITION BY "warung_id", "master_kategori_id"
                   ORDER BY "created_at" DESC
               ) as rn
        FROM "KATEGORI_PRODUK"
        WHERE "master_kategori_id" IS NOT NULL
    ) sub
    WHERE rn > 1
);
