-- Migration: Add Master Kategori Pengeluaran
-- Description: Create master table and update existing category table

-- 1. Create MASTER_KATEGORI_PENGELUARAN
CREATE TABLE IF NOT EXISTS "MASTER_KATEGORI_PENGELUARAN" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "nama_kategori" TEXT NOT NULL,
    "tipe" expense_category_type NOT NULL,
    "icon" TEXT,
    "sort_order" INT DEFAULT 0,
    "is_active" BOOLEAN DEFAULT true,
    "created_at" TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE "MASTER_KATEGORI_PENGELUARAN" IS 'Master list of expense categories suggested to new users.';

-- 2. Modify KATEGORI_PENGELUARAN to match
ALTER TABLE "KATEGORI_PENGELUARAN" 
ADD COLUMN IF NOT EXISTS "icon" TEXT,
ADD COLUMN IF NOT EXISTS "sort_order" INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS "master_kategori_id" UUID REFERENCES "MASTER_KATEGORI_PENGELUARAN"("id") ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_kategori_pengeluaran_master ON "KATEGORI_PENGELUARAN"("master_kategori_id");

-- 3. Seed initial data
INSERT INTO "MASTER_KATEGORI_PENGELUARAN" ("nama_kategori", "tipe", "icon", "sort_order") 
SELECT 'Belanja Stok', 'business', 'BelanjaStok.png', 1 WHERE NOT EXISTS (SELECT 1 FROM "MASTER_KATEGORI_PENGELUARAN" WHERE nama_kategori = 'Belanja Stok');

INSERT INTO "MASTER_KATEGORI_PENGELUARAN" ("nama_kategori", "tipe", "icon", "sort_order") 
SELECT 'Gaji Karyawan', 'business', 'GajiKaryawan.png', 2 WHERE NOT EXISTS (SELECT 1 FROM "MASTER_KATEGORI_PENGELUARAN" WHERE nama_kategori = 'Gaji Karyawan');

INSERT INTO "MASTER_KATEGORI_PENGELUARAN" ("nama_kategori", "tipe", "icon", "sort_order") 
SELECT 'Sewa Tempat', 'business', 'SewaTempat.png', 3 WHERE NOT EXISTS (SELECT 1 FROM "MASTER_KATEGORI_PENGELUARAN" WHERE nama_kategori = 'Sewa Tempat');

INSERT INTO "MASTER_KATEGORI_PENGELUARAN" ("nama_kategori", "tipe", "icon", "sort_order") 
SELECT 'Listrik & Air', 'business', 'ListrikAir.png', 4 WHERE NOT EXISTS (SELECT 1 FROM "MASTER_KATEGORI_PENGELUARAN" WHERE nama_kategori = 'Listrik & Air');

INSERT INTO "MASTER_KATEGORI_PENGELUARAN" ("nama_kategori", "tipe", "icon", "sort_order") 
SELECT 'Transportasi', 'business', 'Transport.png', 5 WHERE NOT EXISTS (SELECT 1 FROM "MASTER_KATEGORI_PENGELUARAN" WHERE nama_kategori = 'Transportasi');

INSERT INTO "MASTER_KATEGORI_PENGELUARAN" ("nama_kategori", "tipe", "icon", "sort_order") 
SELECT 'Kebutuhan Dapur', 'personal', 'MakanDapur.png', 6 WHERE NOT EXISTS (SELECT 1 FROM "MASTER_KATEGORI_PENGELUARAN" WHERE nama_kategori = 'Kebutuhan Dapur');

INSERT INTO "MASTER_KATEGORI_PENGELUARAN" ("nama_kategori", "tipe", "icon", "sort_order") 
SELECT 'Kesehatan', 'personal', 'Kesehatan.png', 7 WHERE NOT EXISTS (SELECT 1 FROM "MASTER_KATEGORI_PENGELUARAN" WHERE nama_kategori = 'Kesehatan');

INSERT INTO "MASTER_KATEGORI_PENGELUARAN" ("nama_kategori", "tipe", "icon", "sort_order") 
SELECT 'Pendidikan', 'personal', 'Pendidikan.png', 8 WHERE NOT EXISTS (SELECT 1 FROM "MASTER_KATEGORI_PENGELUARAN" WHERE nama_kategori = 'Pendidikan');

INSERT INTO "MASTER_KATEGORI_PENGELUARAN" ("nama_kategori", "tipe", "icon", "sort_order") 
SELECT 'Sedekah / Sosial', 'personal', 'Sedekah.png', 9 WHERE NOT EXISTS (SELECT 1 FROM "MASTER_KATEGORI_PENGELUARAN" WHERE nama_kategori = 'Sedekah / Sosial');

INSERT INTO "MASTER_KATEGORI_PENGELUARAN" ("nama_kategori", "tipe", "icon", "sort_order") 
SELECT 'Pakaian', 'personal', 'Pakaian.png', 10 WHERE NOT EXISTS (SELECT 1 FROM "MASTER_KATEGORI_PENGELUARAN" WHERE nama_kategori = 'Pakaian');
