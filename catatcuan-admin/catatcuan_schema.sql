-- CatatCuan Database Schema for Supabase (PostgreSQL)
-- Version: 1.0
-- Generated from: 02_erd_diagram.md

-- =================================================================
-- 1. EXTENSIONS & CUSTOM TYPES (ENUMS)
-- =================================================================

-- Enable pgcrypto for UUID generation if not already enabled
-- Supabase should have this enabled by default.
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE "user_status" AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE "payment_method" AS ENUM ('tunai', 'hutang');
CREATE TYPE "transaction_status" AS ENUM ('completed', 'cancelled');
CREATE TYPE "expense_category_type" AS ENUM ('business', 'personal');
CREATE TYPE "cash_flow_type" AS ENUM ('masuk', 'keluar');
CREATE TYPE "cash_flow_source" AS ENUM ('penjualan', 'pengeluaran', 'hutang_bayar', 'saldo_awal');
CREATE TYPE "debt_status" AS ENUM ('belum_lunas', 'lunas', 'lewat_jatuh_tempo');
CREATE TYPE "payment_method_debt" AS ENUM ('tunai', 'transfer');
CREATE TYPE "admin_role" AS ENUM ('superadmin', 'admin');

-- =================================================================
-- 2. TABLE CREATION
-- =================================================================

-- Order of creation matters due to foreign key constraints.

-- ==================== ADMIN ENTITIES ====================

CREATE TABLE "ADMIN_USERS" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "email" TEXT NOT NULL UNIQUE,
    "password_hash" TEXT NOT NULL,
    "role" admin_role NOT NULL,
    "created_at" TIMESTAMPTZ DEFAULT now(),
    "last_login_at" TIMESTAMPTZ
);
COMMENT ON TABLE "ADMIN_USERS" IS 'Admin users for managing the application.';

CREATE TABLE "APP_CONFIG" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "key" TEXT NOT NULL UNIQUE,
    "value" TEXT,
    "description" TEXT,
    "updated_at" TIMESTAMPTZ DEFAULT now(),
    "updated_by" UUID REFERENCES "ADMIN_USERS"("id")
);
COMMENT ON TABLE "APP_CONFIG" IS 'Application-wide configuration settings.';

CREATE TABLE "MASTER_KATEGORI_PRODUK" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "nama_kategori" TEXT NOT NULL,
    "icon" TEXT,
    "sort_order" INT DEFAULT 0,
    "is_active" BOOLEAN DEFAULT true,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "MASTER_KATEGORI_PRODUK" IS 'Master list of product categories suggested to new users.';

CREATE TABLE "SYSTEM_LOGS" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "action" TEXT NOT NULL,
    "admin_id" UUID REFERENCES "ADMIN_USERS"("id"),
    "details" JSONB,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "SYSTEM_LOGS" IS 'Logs for critical system events.';

-- ==================== CORE ENTITIES ====================

CREATE TABLE "USERS" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "phone_number" TEXT NOT NULL UNIQUE,
    "password_hash" TEXT NOT NULL,
    "status" user_status NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMPTZ DEFAULT now(),
    "updated_at" TIMESTAMPTZ DEFAULT now(),
    "last_login_at" TIMESTAMPTZ
);
COMMENT ON TABLE "USERS" IS 'End-users who own warungs.';

CREATE TABLE "WARUNG" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES "USERS"("id"),
    "nama_warung" TEXT NOT NULL,
    "nama_pemilik" TEXT,
    "alamat" TEXT,
    "phone" TEXT,
    "saldo_awal" DECIMAL(15, 2) DEFAULT 0.00,
    "created_at" TIMESTAMPTZ DEFAULT now(),
    "updated_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "WARUNG" IS 'The shop or business profile owned by a user.';

-- ==================== PRODUK ====================

CREATE TABLE "KATEGORI_PRODUK" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "nama_kategori" TEXT NOT NULL,
    "icon" TEXT,
    "sort_order" INT DEFAULT 0,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "KATEGORI_PRODUK" IS 'Product categories specific to a warung.';

CREATE TABLE "PRODUK" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "kategori_id" UUID REFERENCES "KATEGORI_PRODUK"("id") ON DELETE SET NULL,
    "nama_produk" TEXT NOT NULL,
    "barcode" TEXT,
    "harga_modal" DECIMAL(15, 2) NOT NULL,
    "harga_jual" DECIMAL(15, 2) NOT NULL,
    "stok_saat_ini" INT NOT NULL DEFAULT 0,
    "stok_minimum" INT DEFAULT 0,
    "satuan" TEXT,
    "is_active" BOOLEAN DEFAULT true,
    "created_at" TIMESTAMPTZ DEFAULT now(),
    "updated_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "PRODUK" IS 'Products available in a warung.';

-- ==================== PELANGGAN ====================

CREATE TABLE "PELANGGAN" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "nama" TEXT NOT NULL,
    "phone" TEXT,
    "alamat" TEXT,
    "total_hutang" DECIMAL(15, 2) DEFAULT 0.00,
    "created_at" TIMESTAMPTZ DEFAULT now(),
    "updated_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "PELANGGAN" IS 'Customers of a warung.';
COMMENT ON COLUMN "PELANGGAN"."total_hutang" IS 'Denormalized for quick access. Should be updated via triggers or application logic.';

-- ==================== TRANSAKSI PENJUALAN ====================

CREATE TABLE "PENJUALAN" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "pelanggan_id" UUID REFERENCES "PELANGGAN"("id"),
    "invoice_no" TEXT NOT NULL,
    "tanggal" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "total_amount" DECIMAL(15, 2) NOT NULL,
    "amount_paid" DECIMAL(15, 2) NOT NULL,
    "amount_change" DECIMAL(15, 2) DEFAULT 0.00,
    "payment_method" payment_method NOT NULL,
    "status" transaction_status NOT NULL DEFAULT 'completed',
    "notes" TEXT,
    "created_at" TIMESTAMPTZ DEFAULT now(),
    "updated_at" TIMESTAMPTZ DEFAULT now(),
    UNIQUE("warung_id", "invoice_no")
);
COMMENT ON TABLE "PENJUALAN" IS 'Sales transaction header.';
COMMENT ON COLUMN "PENJUALAN"."pelanggan_id" IS 'Can be NULL for anonymous cash sales.';

CREATE TABLE "PENJUALAN_ITEM" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "penjualan_id" UUID NOT NULL REFERENCES "PENJUALAN"("id") ON DELETE CASCADE,
    "produk_id" UUID NOT NULL REFERENCES "PRODUK"("id"),
    "nama_produk" TEXT,
    "quantity" INT NOT NULL,
    "harga_satuan" DECIMAL(15, 2) NOT NULL,
    "subtotal" DECIMAL(15, 2) NOT NULL,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "PENJUALAN_ITEM" IS 'Individual items within a sales transaction.';
COMMENT ON COLUMN "PENJUALAN_ITEM"."nama_produk" IS 'Snapshot of product name at time of sale.';
COMMENT ON COLUMN "PENJUALAN_ITEM"."harga_satuan" IS 'Snapshot of price at time of sale.';

-- ==================== PENGELUARAN ====================

CREATE TABLE "KATEGORI_PENGELUARAN" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "nama_kategori" TEXT NOT NULL,
    "tipe" expense_category_type NOT NULL,
    "is_system" BOOLEAN DEFAULT false
);
COMMENT ON TABLE "KATEGORI_PENGELUARAN" IS 'Expense categories (e.g., stock purchase, operational).';

CREATE TABLE "PENGELUARAN" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "kategori_id" UUID NOT NULL REFERENCES "KATEGORI_PENGELUARAN"("id"),
    "tanggal" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "amount" DECIMAL(15, 2) NOT NULL,
    "keterangan" TEXT,
    "bukti_foto" TEXT,
    "created_at" TIMESTAMPTZ DEFAULT now(),
    "updated_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "PENGELUARAN" IS 'Records of warung expenses.';
COMMENT ON COLUMN "PENGELUARAN"."bukti_foto" IS 'URL to the receipt photo.';

-- ==================== HUTANG ====================

CREATE TABLE "HUTANG" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "pelanggan_id" UUID NOT NULL REFERENCES "PELANGGAN"("id"),
    "penjualan_id" UUID UNIQUE REFERENCES "PENJUALAN"("id"),
    "amount_awal" DECIMAL(15, 2) NOT NULL,
    "amount_terbayar" DECIMAL(15, 2) DEFAULT 0.00,
    "amount_sisa" DECIMAL(15, 2) NOT NULL,
    "tanggal_jatuh_tempo" DATE,
    "status" debt_status NOT NULL,
    "created_at" TIMESTAMPTZ DEFAULT now(),
    "updated_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "HUTANG" IS 'Debt records from customers.';
COMMENT ON COLUMN "HUTANG"."penjualan_id" IS 'The original sale that created the debt.';

CREATE TABLE "PEMBAYARAN_HUTANG" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "hutang_id" UUID NOT NULL REFERENCES "HUTANG"("id"),
    "tanggal" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "amount" DECIMAL(15, 2) NOT NULL,
    "metode_bayar" payment_method_debt NOT NULL,
    "notes" TEXT,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "PEMBAYARAN_HUTANG" IS 'Records of debt payments.';

-- ==================== BUKU KAS ====================

CREATE TABLE "BUKU_KAS" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "tanggal" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "tipe" cash_flow_type NOT NULL,
    "sumber" cash_flow_source NOT NULL,
    "reference_id" UUID,
    "reference_type" TEXT,
    "amount" DECIMAL(15, 2) NOT NULL,
    "saldo_setelah" DECIMAL(15, 2) NOT NULL,
    "keterangan" TEXT,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "BUKU_KAS" IS 'A journal of all cash flowing in and out.';
COMMENT ON COLUMN "BUKU_KAS"."reference_id" IS 'ID of the source transaction (e.g., id from PENJUALAN).';
COMMENT ON COLUMN "BUKU_KAS"."saldo_setelah" IS 'Running balance. Needs to be calculated carefully.';

-- ==================== LAPORAN (CACHE) ====================

CREATE TABLE "LAPORAN_HARIAN" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "tanggal" DATE NOT NULL,
    "total_penjualan" DECIMAL(15, 2) DEFAULT 0.00,
    "total_pengeluaran_bisnis" DECIMAL(15, 2) DEFAULT 0.00,
    "total_pengeluaran_pribadi" DECIMAL(15, 2) DEFAULT 0.00,
    "total_hutang_baru" DECIMAL(15, 2) DEFAULT 0.00,
    "total_hutang_terbayar" DECIMAL(15, 2) DEFAULT 0.00,
    "profit" DECIMAL(15, 2) DEFAULT 0.00,
    "jumlah_transaksi" INT DEFAULT 0,
    "calculated_at" TIMESTAMPTZ DEFAULT now(),
    UNIQUE("warung_id", "tanggal")
);
COMMENT ON TABLE "LAPORAN_HARIAN" IS 'Pre-calculated daily reports for performance.';


-- =================================================================
-- 3. INDEXING STRATEGY
-- =================================================================

-- Foreign Keys (Rule #13)
CREATE INDEX idx_warung_user ON "WARUNG"(user_id);
CREATE INDEX idx_kategori_produk_warung ON "KATEGORI_PRODUK"(warung_id);
CREATE INDEX idx_produk_warung ON "PRODUK"(warung_id);
CREATE INDEX idx_produk_kategori ON "PRODUK"(kategori_id);
CREATE INDEX idx_pelanggan_warung ON "PELANGGAN"(warung_id);
CREATE INDEX idx_penjualan_warung ON "PENJUALAN"(warung_id);
CREATE INDEX idx_penjualan_pelanggan ON "PENJUALAN"(pelanggan_id);
CREATE INDEX idx_penjualan_item_penjualan ON "PENJUALAN_ITEM"(penjualan_id);
CREATE INDEX idx_penjualan_item_produk ON "PENJUALAN_ITEM"(produk_id);
CREATE INDEX idx_kategori_pengeluaran_warung ON "KATEGORI_PENGELUARAN"(warung_id);
CREATE INDEX idx_pengeluaran_warung ON "PENGELUARAN"(warung_id);
CREATE INDEX idx_pengeluaran_kategori ON "PENGELUARAN"(kategori_id);
CREATE INDEX idx_hutang_warung ON "HUTANG"(warung_id);
CREATE INDEX idx_hutang_pelanggan ON "HUTANG"(pelanggan_id);
CREATE INDEX idx_pembayaran_hutang_hutang ON "PEMBAYARAN_HUTANG"(hutang_id);
CREATE INDEX idx_buku_kas_warung ON "BUKU_KAS"(warung_id);
CREATE INDEX idx_laporan_harian_warung ON "LAPORAN_HARIAN"(warung_id);

-- Query Optimization
CREATE INDEX idx_penjualan_tanggal ON "PENJUALAN"(warung_id, tanggal);
CREATE INDEX idx_buku_kas_tanggal ON "BUKU_KAS"(warung_id, tanggal);
CREATE INDEX idx_hutang_status ON "HUTANG"(warung_id, status);
CREATE INDEX idx_produk_active ON "PRODUK"(warung_id, is_active);
CREATE INDEX idx_buku_kas_reference ON "BUKU_KAS"(reference_id, reference_type);
