-- CatatCuan Database Schema for Supabase (PostgreSQL)
-- Version: 1.1 (Idempotent)
-- Generated from: 02_erd_diagram.md

-- =================================================================
-- 1. EXTENSIONS & CUSTOM TYPES (ENUMS)
-- =================================================================

-- Enable pgcrypto for UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$ BEGIN
    CREATE TYPE "user_status" AS ENUM ('active', 'inactive', 'suspended');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "payment_method" AS ENUM ('tunai', 'hutang');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "transaction_status" AS ENUM ('completed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "expense_category_type" AS ENUM ('business', 'personal');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "cash_flow_type" AS ENUM ('masuk', 'keluar');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "cash_flow_source" AS ENUM ('penjualan', 'pengeluaran', 'hutang_bayar', 'saldo_awal');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "debt_status" AS ENUM ('belum_lunas', 'lunas', 'lewat_jatuh_tempo');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "payment_method_debt" AS ENUM ('tunai', 'transfer');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "admin_role" AS ENUM ('superadmin', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- =================================================================
-- 2. TABLE CREATION
-- =================================================================

-- Order of creation matters due to foreign key constraints.

-- ==================== ADMIN ENTITIES ====================

CREATE TABLE IF NOT EXISTS "ADMIN_USERS" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "email" TEXT NOT NULL UNIQUE,
    "password_hash" TEXT NOT NULL,
    "role" admin_role NOT NULL,
    "created_at" TIMESTAMPTZ DEFAULT now(),
    "last_login_at" TIMESTAMPTZ
);
COMMENT ON TABLE "ADMIN_USERS" IS 'Admin users for managing the application.';

CREATE TABLE IF NOT EXISTS "APP_CONFIG" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "key" TEXT NOT NULL UNIQUE,
    "value" TEXT,
    "description" TEXT,
    "updated_at" TIMESTAMPTZ DEFAULT now(),
    "updated_by" UUID REFERENCES "ADMIN_USERS"("id")
);
COMMENT ON TABLE "APP_CONFIG" IS 'Application-wide configuration settings.';

CREATE TABLE IF NOT EXISTS "MASTER_KATEGORI_PRODUK" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "nama_kategori" TEXT NOT NULL,
    "icon" TEXT,
    "sort_order" INT DEFAULT 0,
    "is_active" BOOLEAN DEFAULT true,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "MASTER_KATEGORI_PRODUK" IS 'Master list of product categories suggested to new users.';

CREATE TABLE IF NOT EXISTS "MASTER_SATUAN" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "nama_satuan" TEXT NOT NULL,
    "sort_order" INT DEFAULT 0,
    "is_active" BOOLEAN DEFAULT true,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "MASTER_SATUAN" IS 'Master list of unit measurements suggested to new users.';

CREATE TABLE IF NOT EXISTS "SYSTEM_LOGS" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "action" TEXT NOT NULL,
    "admin_id" UUID REFERENCES "ADMIN_USERS"("id"),
    "details" JSONB,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "SYSTEM_LOGS" IS 'Logs for critical system events.';

-- ==================== CORE ENTITIES ====================

CREATE TABLE IF NOT EXISTS "USERS" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "phone_number" TEXT NOT NULL UNIQUE,
    "password_hash" TEXT NOT NULL,
    "status" user_status NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMPTZ DEFAULT now(),
    "updated_at" TIMESTAMPTZ DEFAULT now(),
    "last_login_at" TIMESTAMPTZ
);
COMMENT ON TABLE "USERS" IS 'End-users who own warungs.';

CREATE TABLE IF NOT EXISTS "MOBILE_DEVICE_TOKENS" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES "USERS"("id") ON DELETE CASCADE,
    "device_token" TEXT NOT NULL UNIQUE,
    "platform" TEXT NOT NULL,
    "device_label" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_seen_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "last_error" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE "MOBILE_DEVICE_TOKENS" IS 'Stores Firebase Cloud Messaging tokens for each logged-in mobile device.';

CREATE TABLE IF NOT EXISTS "USER_NOTIFICATION_PREFERENCES" (
    "user_id" UUID PRIMARY KEY REFERENCES "USERS"("id") ON DELETE CASCADE,
    "push_enabled" BOOLEAN NOT NULL DEFAULT true,
    "sms_enabled" BOOLEAN NOT NULL DEFAULT true,
    "due_date_reminder" BOOLEAN NOT NULL DEFAULT true,
    "low_stock_alert" BOOLEAN NOT NULL DEFAULT true,
    "daily_reminder" BOOLEAN NOT NULL DEFAULT false,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE "USER_NOTIFICATION_PREFERENCES" IS 'Server-side copy of notification preferences so backend jobs can respect user settings.';

CREATE TABLE IF NOT EXISTS "PASSWORD_RESET_OTPS" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL REFERENCES "USERS"("id") ON DELETE CASCADE,
    "phone_number" TEXT NOT NULL,
    "code_hash" TEXT NOT NULL,
    "channel" TEXT NOT NULL DEFAULT 'sms',
    "expires_at" TIMESTAMPTZ NOT NULL,
    "used_at" TIMESTAMPTZ,
    "attempt_count" INT NOT NULL DEFAULT 0,
    "sent_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE "PASSWORD_RESET_OTPS" IS 'Stores one-time password reset codes sent to users.';

CREATE TABLE IF NOT EXISTS "WARUNG" (
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

CREATE TABLE IF NOT EXISTS "NOTIFICATION_LOGS" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID REFERENCES "USERS"("id") ON DELETE SET NULL,
    "warung_id" UUID REFERENCES "WARUNG"("id") ON DELETE SET NULL,
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
COMMENT ON TABLE "NOTIFICATION_LOGS" IS 'Outbound push/SMS notification audit log.';

-- ==================== PRODUK ====================

CREATE TABLE IF NOT EXISTS "KATEGORI_PRODUK" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "nama_kategori" TEXT NOT NULL,
    "icon" TEXT,
    "sort_order" INT DEFAULT 0,
    "master_kategori_id" UUID REFERENCES "MASTER_KATEGORI_PRODUK"("id") ON DELETE SET NULL,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "KATEGORI_PRODUK" IS 'Product categories specific to a warung.';
CREATE INDEX IF NOT EXISTS idx_kategori_produk_master ON "KATEGORI_PRODUK"("master_kategori_id");

CREATE TABLE IF NOT EXISTS "SATUAN_PRODUK" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "nama_satuan" TEXT NOT NULL,
    "sort_order" INT DEFAULT 0,
    "master_satuan_id" UUID REFERENCES "MASTER_SATUAN"("id") ON DELETE SET NULL,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE "SATUAN_PRODUK" IS 'Unit measurements specific to a warung.';
CREATE INDEX IF NOT EXISTS idx_satuan_produk_master ON "SATUAN_PRODUK"("master_satuan_id");

CREATE TABLE IF NOT EXISTS "PRODUK" (
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

CREATE TABLE IF NOT EXISTS "PELANGGAN" (
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

CREATE TABLE IF NOT EXISTS "PENJUALAN" (
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
ALTER TABLE "PENJUALAN"
    ADD COLUMN IF NOT EXISTS "profit" DECIMAL(15, 2) DEFAULT 0.00;
COMMENT ON TABLE "PENJUALAN" IS 'Sales transaction header.';
COMMENT ON COLUMN "PENJUALAN"."pelanggan_id" IS 'Can be NULL for anonymous cash sales.';
COMMENT ON COLUMN "PENJUALAN"."profit" IS 'Net profit snapshot for the sale after discount.';

CREATE TABLE IF NOT EXISTS "PENJUALAN_ITEM" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "penjualan_id" UUID NOT NULL REFERENCES "PENJUALAN"("id") ON DELETE CASCADE,
    "produk_id" UUID NOT NULL REFERENCES "PRODUK"("id"),
    "nama_produk" TEXT,
    "quantity" INT NOT NULL,
    "harga_satuan" DECIMAL(15, 2) NOT NULL,
    "subtotal" DECIMAL(15, 2) NOT NULL,
    "created_at" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE "PENJUALAN_ITEM"
    ADD COLUMN IF NOT EXISTS "harga_modal" DECIMAL(15, 2) DEFAULT 0.00;
COMMENT ON TABLE "PENJUALAN_ITEM" IS 'Individual items within a sales transaction.';
COMMENT ON COLUMN "PENJUALAN_ITEM"."nama_produk" IS 'Snapshot of product name at time of sale.';
COMMENT ON COLUMN "PENJUALAN_ITEM"."harga_satuan" IS 'Snapshot of price at time of sale.';
COMMENT ON COLUMN "PENJUALAN_ITEM"."harga_modal" IS 'Snapshot of cost price at time of sale.';

-- ==================== PENGELUARAN ====================

CREATE TABLE IF NOT EXISTS "KATEGORI_PENGELUARAN" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "nama_kategori" TEXT NOT NULL,
    "tipe" expense_category_type NOT NULL,
    "is_system" BOOLEAN DEFAULT false
);
COMMENT ON TABLE "KATEGORI_PENGELUARAN" IS 'Expense categories (e.g., stock purchase, operational).';

CREATE TABLE IF NOT EXISTS "PENGELUARAN" (
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

CREATE TABLE IF NOT EXISTS "HUTANG" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "warung_id" UUID NOT NULL REFERENCES "WARUNG"("id") ON DELETE CASCADE,
    "pelanggan_id" UUID NOT NULL REFERENCES "PELANGGAN"("id"),
    "penjualan_id" UUID UNIQUE REFERENCES "PENJUALAN"("id"),
    "catatan" TEXT,
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

CREATE TABLE IF NOT EXISTS "PEMBAYARAN_HUTANG" (
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

CREATE TABLE IF NOT EXISTS "BUKU_KAS" (
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

CREATE TABLE IF NOT EXISTS "LAPORAN_HARIAN" (
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
CREATE INDEX IF NOT EXISTS idx_warung_user ON "WARUNG"(user_id);
CREATE INDEX IF NOT EXISTS idx_mobile_device_tokens_user ON "MOBILE_DEVICE_TOKENS"("user_id", "is_active");
CREATE INDEX IF NOT EXISTS idx_kategori_produk_warung ON "KATEGORI_PRODUK"(warung_id);
CREATE INDEX IF NOT EXISTS idx_produk_warung ON "PRODUK"(warung_id);
CREATE INDEX IF NOT EXISTS idx_produk_kategori ON "PRODUK"(kategori_id);
CREATE INDEX IF NOT EXISTS idx_pelanggan_warung ON "PELANGGAN"(warung_id);
CREATE INDEX IF NOT EXISTS idx_penjualan_warung ON "PENJUALAN"(warung_id);
CREATE INDEX IF NOT EXISTS idx_penjualan_pelanggan ON "PENJUALAN"(pelanggan_id);
CREATE INDEX IF NOT EXISTS idx_penjualan_item_penjualan ON "PENJUALAN_ITEM"(penjualan_id);
CREATE INDEX IF NOT EXISTS idx_penjualan_item_produk ON "PENJUALAN_ITEM"(produk_id);
CREATE INDEX IF NOT EXISTS idx_kategori_pengeluaran_warung ON "KATEGORI_PENGELUARAN"(warung_id);
CREATE INDEX IF NOT EXISTS idx_pengeluaran_warung ON "PENGELUARAN"(warung_id);
CREATE INDEX IF NOT EXISTS idx_pengeluaran_kategori ON "PENGELUARAN"(kategori_id);
CREATE INDEX IF NOT EXISTS idx_hutang_warung ON "HUTANG"(warung_id);
CREATE INDEX IF NOT EXISTS idx_hutang_pelanggan ON "HUTANG"(pelanggan_id);
CREATE INDEX IF NOT EXISTS idx_pembayaran_hutang_hutang ON "PEMBAYARAN_HUTANG"(hutang_id);
CREATE INDEX IF NOT EXISTS idx_buku_kas_warung ON "BUKU_KAS"(warung_id);
CREATE INDEX IF NOT EXISTS idx_laporan_harian_warung ON "LAPORAN_HARIAN"(warung_id);
CREATE INDEX IF NOT EXISTS idx_password_reset_otps_user ON "PASSWORD_RESET_OTPS"("user_id", "created_at");
CREATE INDEX IF NOT EXISTS idx_password_reset_otps_phone ON "PASSWORD_RESET_OTPS"("phone_number", "created_at");
CREATE INDEX IF NOT EXISTS idx_notification_logs_user ON "NOTIFICATION_LOGS"("user_id", "created_at");

-- Query Optimization
CREATE INDEX IF NOT EXISTS idx_penjualan_tanggal ON "PENJUALAN"(warung_id, tanggal);
CREATE INDEX IF NOT EXISTS idx_buku_kas_tanggal ON "BUKU_KAS"(warung_id, tanggal);
CREATE INDEX IF NOT EXISTS idx_hutang_status ON "HUTANG"(warung_id, status);
CREATE INDEX IF NOT EXISTS idx_produk_active ON "PRODUK"(warung_id, is_active);
CREATE INDEX IF NOT EXISTS idx_buku_kas_reference ON "BUKU_KAS"(reference_id, reference_type);
CREATE INDEX IF NOT EXISTS idx_notification_logs_channel_status ON "NOTIFICATION_LOGS"("channel", "status", "created_at");
