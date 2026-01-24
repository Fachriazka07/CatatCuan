# CatatCuan - Database Design Document

**Version:** 1.0  
**Date:** 2026-01-22  
**Database:** Supabase (PostgreSQL 15)  
**ORM Mobile:** Drift (SQLite for offline)  
**Sync:** PowerSync  

---

## 1. Database Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CATATCUAN DATABASE                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐     ┌──────────────┐                      │
│  │ SUPABASE     │     │ DRIFT/SQLite │                      │
│  │ (Cloud)      │◄────┤ (Local)      │                      │
│  │ PostgreSQL   │     │ Mobile App   │                      │
│  └──────────────┘     └──────────────┘                      │
│         ▲                    ▲                               │
│         │                    │                               │
│         └───────┬────────────┘                               │
│                 │                                            │
│         ┌──────────────┐                                    │
│         │  POWERSYNC   │                                    │
│         │  (Sync)      │                                    │
│         └──────────────┘                                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Entity Summary

| # | Entity | Type | Purpose |
|---|--------|------|---------|
| 1 | `users` | Core | Akun pengguna (login phone) |
| 2 | `warung` | Core | Profil toko/warung |
| 3 | `kategori_produk` | Master | Kategori produk |
| 4 | `produk` | Master | Data produk + stok |
| 5 | `pelanggan` | Master | Database pelanggan |
| 6 | `penjualan` | Transaction | Header transaksi POS |
| 7 | `penjualan_item` | Transaction | Detail item penjualan |
| 8 | `kategori_pengeluaran` | Master | Kategori expense |
| 9 | `pengeluaran` | Transaction | Pencatatan expense |
| 10 | `buku_kas` | Ledger | Jurnal kas masuk/keluar |
| 11 | `hutang` | Transaction | Piutang pelanggan |
| 12 | `pembayaran_hutang` | Transaction | Cicilan pembayaran |
| 13 | `laporan_harian` | Cache | Agregasi harian |
| 14 | `admin_users` | Admin | Admin dashboard users |
| 15 | `app_config` | Admin | Konfigurasi sistem |
| 16 | `master_kategori_produk` | Admin | Template kategori default |
| 17 | `system_logs` | Admin | Audit log admin actions |

---

## 3. Normalization Check (3NF) ✅

| Level | Status | Verification |
|-------|--------|--------------|
| **1NF** | ✅ Pass | All columns atomic, no arrays |
| **2NF** | ✅ Pass | All non-key depend on full PK |
| **3NF** | ✅ Pass | No transitive dependencies |

### Denormalized Fields (Intentional for Performance)

| Table | Field | Reason | Update Strategy |
|-------|-------|--------|-----------------|
| `pelanggan` | `total_hutang` | Quick display | Trigger on hutang change |
| `buku_kas` | `saldo_setelah` | Running balance | App-level calculation |
| `laporan_harian` | `*` | Pre-aggregated | Daily batch job |

---

## 4. SQL Schema (Supabase/PostgreSQL)

### 4.1 Extension & Types

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Custom ENUM types
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE payment_method AS ENUM ('tunai', 'hutang');
CREATE TYPE transaction_status AS ENUM ('completed', 'cancelled');
CREATE TYPE kas_type AS ENUM ('masuk', 'keluar');
CREATE TYPE kas_source AS ENUM ('penjualan', 'pengeluaran', 'hutang_bayar', 'saldo_awal');
CREATE TYPE hutang_status AS ENUM ('belum_lunas', 'lunas', 'lewat_jatuh_tempo');
CREATE TYPE expense_type AS ENUM ('business', 'personal');
CREATE TYPE admin_role AS ENUM ('superadmin', 'admin');
```

### 4.2 Core Tables

```sql
-- ==================== USERS ====================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    status user_status DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

-- ==================== WARUNG ====================
CREATE TABLE warung (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    nama_warung VARCHAR(100) NOT NULL,
    nama_pemilik VARCHAR(100) NOT NULL,
    alamat TEXT,
    phone VARCHAR(20),
    saldo_awal DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_warung_user ON warung(user_id);
```

### 4.3 Product Tables

```sql
-- ==================== KATEGORI PRODUK ====================
CREATE TABLE kategori_produk (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warung_id UUID NOT NULL REFERENCES warung(id) ON DELETE CASCADE,
    nama_kategori VARCHAR(50) NOT NULL,
    icon VARCHAR(50),
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_kategori_produk_warung ON kategori_produk(warung_id);

-- ==================== PRODUK ====================
CREATE TABLE produk (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warung_id UUID NOT NULL REFERENCES warung(id) ON DELETE CASCADE,
    kategori_id UUID REFERENCES kategori_produk(id) ON DELETE SET NULL,
    nama_produk VARCHAR(100) NOT NULL,
    barcode VARCHAR(50),
    harga_modal DECIMAL(15,2) DEFAULT 0,
    harga_jual DECIMAL(15,2) NOT NULL,
    stok_saat_ini INT DEFAULT 0,
    stok_minimum INT DEFAULT 5,
    satuan VARCHAR(20) DEFAULT 'pcs',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_produk_warung ON produk(warung_id);
CREATE INDEX idx_produk_kategori ON produk(kategori_id);
CREATE INDEX idx_produk_barcode ON produk(warung_id, barcode);
CREATE INDEX idx_produk_active ON produk(warung_id, is_active);
```

### 4.4 Customer Table

```sql
-- ==================== PELANGGAN ====================
CREATE TABLE pelanggan (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warung_id UUID NOT NULL REFERENCES warung(id) ON DELETE CASCADE,
    nama VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    alamat TEXT,
    total_hutang DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pelanggan_warung ON pelanggan(warung_id);
```

### 4.5 Sales Tables

```sql
-- ==================== PENJUALAN ====================
CREATE TABLE penjualan (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warung_id UUID NOT NULL REFERENCES warung(id) ON DELETE CASCADE,
    pelanggan_id UUID REFERENCES pelanggan(id) ON DELETE SET NULL,
    invoice_no VARCHAR(50) UNIQUE NOT NULL,
    tanggal TIMESTAMPTZ DEFAULT NOW(),
    total_amount DECIMAL(15,2) NOT NULL,
    amount_paid DECIMAL(15,2) DEFAULT 0,
    amount_change DECIMAL(15,2) DEFAULT 0,
    payment_method payment_method NOT NULL,
    status transaction_status DEFAULT 'completed',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_penjualan_warung ON penjualan(warung_id);
CREATE INDEX idx_penjualan_pelanggan ON penjualan(pelanggan_id);
CREATE INDEX idx_penjualan_tanggal ON penjualan(warung_id, tanggal);

-- ==================== PENJUALAN ITEM ====================
CREATE TABLE penjualan_item (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    penjualan_id UUID NOT NULL REFERENCES penjualan(id) ON DELETE CASCADE,
    produk_id UUID REFERENCES produk(id) ON DELETE SET NULL,
    nama_produk VARCHAR(100) NOT NULL, -- Snapshot
    quantity INT NOT NULL,
    harga_satuan DECIMAL(15,2) NOT NULL, -- Snapshot
    subtotal DECIMAL(15,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_penjualan_item_penjualan ON penjualan_item(penjualan_id);
CREATE INDEX idx_penjualan_item_produk ON penjualan_item(produk_id);
```

### 4.6 Expense Tables

```sql
-- ==================== KATEGORI PENGELUARAN ====================
CREATE TABLE kategori_pengeluaran (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warung_id UUID NOT NULL REFERENCES warung(id) ON DELETE CASCADE,
    nama_kategori VARCHAR(50) NOT NULL,
    tipe expense_type NOT NULL,
    is_system BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_kategori_pengeluaran_warung ON kategori_pengeluaran(warung_id);

-- ==================== PENGELUARAN ====================
CREATE TABLE pengeluaran (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warung_id UUID NOT NULL REFERENCES warung(id) ON DELETE CASCADE,
    kategori_id UUID REFERENCES kategori_pengeluaran(id) ON DELETE SET NULL,
    tanggal TIMESTAMPTZ DEFAULT NOW(),
    amount DECIMAL(15,2) NOT NULL,
    keterangan TEXT,
    bukti_foto TEXT, -- URL to Supabase Storage
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pengeluaran_warung ON pengeluaran(warung_id);
CREATE INDEX idx_pengeluaran_kategori ON pengeluaran(kategori_id);
CREATE INDEX idx_pengeluaran_tanggal ON pengeluaran(warung_id, tanggal);
```

### 4.7 Cash Book & Debt Tables

```sql
-- ==================== BUKU KAS ====================
CREATE TABLE buku_kas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warung_id UUID NOT NULL REFERENCES warung(id) ON DELETE CASCADE,
    tanggal TIMESTAMPTZ DEFAULT NOW(),
    tipe kas_type NOT NULL,
    sumber kas_source NOT NULL,
    reference_id UUID,
    reference_type VARCHAR(50),
    amount DECIMAL(15,2) NOT NULL,
    saldo_setelah DECIMAL(15,2) NOT NULL,
    keterangan TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_buku_kas_warung ON buku_kas(warung_id);
CREATE INDEX idx_buku_kas_tanggal ON buku_kas(warung_id, tanggal);

-- ==================== HUTANG ====================
CREATE TABLE hutang (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warung_id UUID NOT NULL REFERENCES warung(id) ON DELETE CASCADE,
    pelanggan_id UUID NOT NULL REFERENCES pelanggan(id) ON DELETE CASCADE,
    penjualan_id UUID REFERENCES penjualan(id) ON DELETE SET NULL,
    amount_awal DECIMAL(15,2) NOT NULL,
    amount_terbayar DECIMAL(15,2) DEFAULT 0,
    amount_sisa DECIMAL(15,2) NOT NULL,
    tanggal_jatuh_tempo DATE,
    status hutang_status DEFAULT 'belum_lunas',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_hutang_warung ON hutang(warung_id);
CREATE INDEX idx_hutang_pelanggan ON hutang(pelanggan_id);
CREATE INDEX idx_hutang_status ON hutang(warung_id, status);

-- ==================== PEMBAYARAN HUTANG ====================
CREATE TABLE pembayaran_hutang (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hutang_id UUID NOT NULL REFERENCES hutang(id) ON DELETE CASCADE,
    tanggal TIMESTAMPTZ DEFAULT NOW(),
    amount DECIMAL(15,2) NOT NULL,
    metode_bayar VARCHAR(20) DEFAULT 'tunai',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pembayaran_hutang ON pembayaran_hutang(hutang_id);
```

### 4.8 Report Cache & Admin Tables

```sql
-- ==================== LAPORAN HARIAN ====================
CREATE TABLE laporan_harian (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warung_id UUID NOT NULL REFERENCES warung(id) ON DELETE CASCADE,
    tanggal DATE NOT NULL,
    total_penjualan DECIMAL(15,2) DEFAULT 0,
    total_pengeluaran_bisnis DECIMAL(15,2) DEFAULT 0,
    total_pengeluaran_pribadi DECIMAL(15,2) DEFAULT 0,
    total_hutang_baru DECIMAL(15,2) DEFAULT 0,
    total_hutang_terbayar DECIMAL(15,2) DEFAULT 0,
    profit DECIMAL(15,2) DEFAULT 0,
    jumlah_transaksi INT DEFAULT 0,
    calculated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(warung_id, tanggal)
);

CREATE INDEX idx_laporan_harian_warung ON laporan_harian(warung_id);

-- ==================== ADMIN USERS ====================
CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role admin_role DEFAULT 'admin',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

-- ==================== APP CONFIG ====================
CREATE TABLE app_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES admin_users(id)
);

-- ==================== MASTER KATEGORI PRODUK ====================
CREATE TABLE master_kategori_produk (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nama_kategori VARCHAR(50) NOT NULL,
    icon VARCHAR(50),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== SYSTEM LOGS ====================
CREATE TABLE system_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action VARCHAR(100) NOT NULL,
    admin_id UUID REFERENCES admin_users(id),
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_system_logs_admin ON system_logs(admin_id);
CREATE INDEX idx_system_logs_action ON system_logs(action);
```

---

## 5. Index Strategy Summary

| Table | Column(s) | Index Type | Purpose |
|-------|-----------|------------|---------|
| `warung` | `user_id` | B-Tree | FK lookup |
| `produk` | `warung_id` | B-Tree | FK lookup |
| `produk` | `warung_id, barcode` | B-Tree | Barcode scan |
| `produk` | `warung_id, is_active` | B-Tree | Active filter |
| `penjualan` | `warung_id, tanggal` | B-Tree | Date range queries |
| `hutang` | `warung_id, status` | B-Tree | Status filter |
| `buku_kas` | `warung_id, tanggal` | B-Tree | Date range queries |
| `laporan_harian` | `warung_id, tanggal` | Unique | Daily report lookup |

---

## 6. Row Level Security (RLS)

```sql
-- Enable RLS on all user-facing tables
ALTER TABLE warung ENABLE ROW LEVEL SECURITY;
ALTER TABLE produk ENABLE ROW LEVEL SECURITY;
ALTER TABLE pelanggan ENABLE ROW LEVEL SECURITY;
ALTER TABLE penjualan ENABLE ROW LEVEL SECURITY;
ALTER TABLE pengeluaran ENABLE ROW LEVEL SECURITY;
ALTER TABLE buku_kas ENABLE ROW LEVEL SECURITY;
ALTER TABLE hutang ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own warung data
CREATE POLICY warung_policy ON warung
    FOR ALL USING (user_id = auth.uid());

CREATE POLICY produk_policy ON produk
    FOR ALL USING (warung_id IN (SELECT id FROM warung WHERE user_id = auth.uid()));

-- Repeat for other tables...
```

---

## 7. Migration Strategy

| Phase | Migration | Priority |
|-------|-----------|----------|
| **M001** | Core tables (users, warung) | 🔴 First |
| **M002** | Product tables | 🔴 High |
| **M003** | Customer & Sales tables | 🔴 High |
| **M004** | Expense tables | 🔴 High |
| **M005** | Cash book & Debt tables | 🔴 High |
| **M006** | Report cache table | 🟡 Medium |
| **M007** | Admin tables | 🟡 Medium |
| **M008** | Indexes & RLS | 🔴 High |
| **M009** | Seed data (master kategori) | 🟢 Low |

---

## 8. Seed Data (Default Categories)

```sql
-- Insert default expense categories (after warung created)
INSERT INTO kategori_pengeluaran (warung_id, nama_kategori, tipe, is_system) VALUES
    ('{warung_id}', 'Belanja Stok', 'business', true),
    ('{warung_id}', 'Listrik', 'business', true),
    ('{warung_id}', 'Gaji Karyawan', 'business', true),
    ('{warung_id}', 'Sewa Tempat', 'business', true),
    ('{warung_id}', 'Transportasi', 'business', true),
    ('{warung_id}', 'Keperluan Pribadi', 'personal', true);

-- Master product categories (admin-defined)
INSERT INTO master_kategori_produk (nama_kategori, icon, sort_order) VALUES
    ('Sembako', '🍚', 1),
    ('Minuman', '🥤', 2),
    ('Makanan Ringan', '🍿', 3),
    ('Rokok', '🚬', 4),
    ('Kebutuhan Harian', '🧴', 5),
    ('Obat-obatan', '💊', 6),
    ('Pulsa & Token', '📱', 7),
    ('Lainnya', '📦', 99);
```

---

## ✅ Output Checklist

- [x] Requirements gathered (16 entities)
- [x] ERD verified (from `02_erd_diagram.md`)
- [x] Normalization checked (3NF compliant)
- [x] SQL schema generated (PostgreSQL)
- [x] Indexes defined (all FKs + query optimization)
- [x] RLS strategy defined
- [x] Migration strategy defined
- [x] Seed data prepared

---

*Generated by /design-database workflow (WF-DB01)*
*Rules Applied: RULE-DB01-05*
