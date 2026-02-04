# CatatCuan - Entity Relationship Diagram (ERD)

**Version:** 1.0  
**Date:** 2026-01-21  
**Normalization:** 3NF Compliant

---

## 1. ERD Diagram

### Visual Diagram (Figma)

![ERD Diagram](file:///d:/Fachri/WORKSPACES/CatatCuan/AI-Agent/Output/Design/CatatCuan/diagrams/erd_diagram.png)

### Mermaid Diagram

```mermaid
erDiagram
    %% ==================== CORE ENTITIES ====================
    
    USERS {
        uuid id PK
        string phone_number UK "Nomor telepon unik"
        string password_hash
        string status "active/inactive/suspended"
        timestamp created_at
        timestamp updated_at
        timestamp last_login_at
    }

    WARUNG {
        uuid id PK
        uuid user_id FK
        string nama_warung
        string nama_pemilik
        string alamat
        string phone
        decimal saldo_awal "Modal awal"
        timestamp created_at
        timestamp updated_at
    }

    %% ==================== PRODUK ====================
    
    KATEGORI_PRODUK {
        uuid id PK
        uuid warung_id FK
        string nama_kategori
        string icon
        int sort_order
        timestamp created_at
    }

    PRODUK {
        uuid id PK
        uuid warung_id FK
        uuid kategori_id FK
        string nama_produk
        string barcode "Scan Barcode Support"
        decimal harga_modal "User term: Harga Modal"
        decimal harga_jual
        int stok_saat_ini
        int stok_minimum "Alert threshold"
        string satuan "pcs/kg/liter"
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    %% ==================== PELANGGAN ====================
    
    PELANGGAN {
        uuid id PK
        uuid warung_id FK
        string nama
        string phone
        string alamat
        decimal total_hutang "Denormalized for quick access"
        timestamp created_at
        timestamp updated_at
    }

    %% ==================== TRANSAKSI PENJUALAN ====================
    
    PENJUALAN {
        uuid id PK
        uuid warung_id FK
        uuid pelanggan_id FK "NULL jika tunai anonymous"
        string invoice_no UK
        timestamp tanggal
        decimal total_amount
        decimal amount_paid
        decimal amount_change "Kembalian (for Receipt)"
        string payment_method "tunai/hutang"
        string status "completed/cancelled"
        string notes
        timestamp created_at
        timestamp updated_at
    }

    PENJUALAN_ITEM {
        uuid id PK
        uuid penjualan_id FK
        uuid produk_id FK
        string nama_produk "Snapshot"
        int quantity
        decimal harga_satuan "Snapshot harga saat transaksi"
        decimal subtotal
        timestamp created_at
    }

    %% ==================== PENGELUARAN ====================
    
    KATEGORI_PENGELUARAN {
        uuid id PK
        uuid warung_id FK
        string nama_kategori "Belanja Stok/Operasional/Pribadi"
        string tipe "business/personal"
        boolean is_system "Kategori default"
        timestamp created_at
    }

    PENGELUARAN {
        uuid id PK
        uuid warung_id FK
        uuid kategori_id FK
        timestamp tanggal
        decimal amount
        string keterangan
        string bukti_foto "URL foto struk"
        timestamp created_at
        timestamp updated_at
    }

    %% ==================== BUKU KAS ====================
    
    BUKU_KAS {
        uuid id PK
        uuid warung_id FK
        timestamp tanggal
        string tipe "masuk/keluar"
        string sumber "penjualan/pengeluaran/hutang_bayar/saldo_awal"
        uuid reference_id "ID transaksi terkait"
        string reference_type "penjualan/pengeluaran/hutang"
        decimal amount
        decimal saldo_setelah "Running balance"
        string keterangan
        timestamp created_at
    }

    %% ==================== HUTANG ====================
    
    HUTANG {
        uuid id PK
        uuid warung_id FK
        uuid pelanggan_id FK
        uuid penjualan_id FK "Transaksi asal hutang"
        decimal amount_awal
        decimal amount_terbayar
        decimal amount_sisa
        date tanggal_jatuh_tempo
        string status "belum_lunas/lunas/lewat_jatuh_tempo"
        timestamp created_at
        timestamp updated_at
    }

    PEMBAYARAN_HUTANG {
        uuid id PK
        uuid hutang_id FK
        timestamp tanggal
        decimal amount
        string metode_bayar "tunai/transfer"
        string notes
        timestamp created_at
    }

    %% ==================== LAPORAN (CACHE) ====================
    
    LAPORAN_HARIAN {
        uuid id PK
        uuid warung_id FK
        date tanggal UK
        decimal total_penjualan
        decimal total_pengeluaran_bisnis
        decimal total_pengeluaran_pribadi
        decimal total_hutang_baru
        decimal total_hutang_terbayar
        decimal profit
        int jumlah_transaksi
        timestamp calculated_at
    }

    %% ==================== ADMIN ENTITIES ====================

    ADMIN_USERS {
        uuid id PK
        string email UK
        string password_hash
        string role "superadmin/admin"
        timestamp created_at
        timestamp last_login_at
    }

    APP_CONFIG {
        uuid id PK
        string key UK "maintenance_mode/min_version/etc"
        string value
        string description
        timestamp updated_at
        uuid updated_by FK
    }

    MASTER_KATEGORI_PRODUK {
        uuid id PK
        string nama_kategori
        string icon
        int sort_order
        boolean is_active
        timestamp created_at
    }

    SYSTEM_LOGS {
        uuid id PK
        string action "backup/cleanup/user_suspend/etc"
        uuid admin_id FK
        string details
        timestamp created_at
    }

    %% ==================== RELATIONSHIPS ====================
    
    USERS ||--o{ WARUNG : "owns"
    WARUNG ||--o{ KATEGORI_PRODUK : "has"
    WARUNG ||--o{ PRODUK : "has"
    KATEGORI_PRODUK ||--o{ PRODUK : "categorizes"
    WARUNG ||--o{ PELANGGAN : "has"
    WARUNG ||--o{ PENJUALAN : "records"
    PELANGGAN ||--o{ PENJUALAN : "makes"
    PENJUALAN ||--|{ PENJUALAN_ITEM : "contains"
    PRODUK ||--o{ PENJUALAN_ITEM : "sold_as"
    WARUNG ||--o{ KATEGORI_PENGELUARAN : "has"
    WARUNG ||--o{ PENGELUARAN : "records"
    KATEGORI_PENGELUARAN ||--o{ PENGELUARAN : "categorizes"
    WARUNG ||--o{ BUKU_KAS : "tracks"
    WARUNG ||--o{ HUTANG : "records"
    PELANGGAN ||--o{ HUTANG : "owes"
    PENJUALAN ||--o| HUTANG : "creates"
    HUTANG ||--o{ PEMBAYARAN_HUTANG : "paid_by"
    WARUNG ||--o{ LAPORAN_HARIAN : "generates"
```

---

## 2. Entity Details

### 2.1 Core Entities

| Entity | Description | Relationships |
|--------|-------------|---------------|
| `USERS` | Akun pengguna aplikasi | 1:N dengan WARUNG |
| `WARUNG` | Profil toko/warung | Parent dari semua entitas bisnis |

### 2.2 Product Management

| Entity | Description | Key Fields |
|--------|-------------|------------|
| `KATEGORI_PRODUK` | Kategori produk (Makanan, Minuman, dll) | nama_kategori, icon |
| `PRODUK` | Master data produk | harga_beli, harga_jual, stok |

### 2.3 Sales & Transactions

| Entity | Description | Key Fields |
|--------|-------------|------------|
| `PENJUALAN` | Header transaksi penjualan | invoice_no, payment_method |
| `PENJUALAN_ITEM` | Detail item per transaksi | quantity, harga_satuan (snapshot) |

### 2.4 Expenses

| Entity | Description | Key Fields |
|--------|-------------|------------|
| `KATEGORI_PENGELUARAN` | Jenis pengeluaran | tipe (business/personal) |
| `PENGELUARAN` | Record pengeluaran | amount, keterangan |

### 2.5 Cash Book

| Entity | Description | Purpose |
|--------|-------------|---------|
| `BUKU_KAS` | Jurnal kas masuk/keluar | Tracking saldo & mutasi |

### 2.6 Debt Management

| Entity | Description | Key Fields |
|--------|-------------|------------|
| `HUTANG` | Record hutang pelanggan | amount_sisa, status |
| `PEMBAYARAN_HUTANG` | Pembayaran cicilan | amount, metode_bayar |

---

## 3. Data Types & Constraints

### UUID Primary Keys
Semua tabel menggunakan `UUID` sebagai primary key untuk:
- Offline-first compatibility
- Conflict-free sync
- No sequential guessing

### Indexing Strategy

```sql
-- Foreign Keys (WAJIB di-index per rule #13)
CREATE INDEX idx_warung_user ON warung(user_id);
CREATE INDEX idx_produk_warung ON produk(warung_id);
CREATE INDEX idx_produk_kategori ON produk(kategori_id);
CREATE INDEX idx_penjualan_warung ON penjualan(warung_id);
CREATE INDEX idx_penjualan_pelanggan ON penjualan(pelanggan_id);
CREATE INDEX idx_penjualan_item_penjualan ON penjualan_item(penjualan_id);
CREATE INDEX idx_pengeluaran_warung ON pengeluaran(warung_id);
CREATE INDEX idx_hutang_pelanggan ON hutang(pelanggan_id);

-- Query Optimization
CREATE INDEX idx_penjualan_tanggal ON penjualan(warung_id, tanggal);
CREATE INDEX idx_buku_kas_tanggal ON buku_kas(warung_id, tanggal);
CREATE INDEX idx_hutang_status ON hutang(warung_id, status);
CREATE INDEX idx_produk_active ON produk(warung_id, is_active);
```

---

## 4. Normalization Verification (3NF)

### ✅ 1NF - Atomic Values
- Semua field berisi nilai atomik
- Tidak ada repeating groups
- Setiap tabel punya primary key

### ✅ 2NF - Full Functional Dependency
- Semua non-key attributes depend on entire primary key
- `PENJUALAN_ITEM` terpisah dari `PENJUALAN`

### ✅ 3NF - No Transitive Dependencies
- Tidak ada field yang depend pada non-key field
- **Exception (Denormalized for Performance):**
  - `PELANGGAN.total_hutang` - cached sum, update via trigger
  - `BUKU_KAS.saldo_setelah` - running balance
  - `LAPORAN_HARIAN.*` - pre-calculated aggregates

---

## 5. Business Rules Encoded

| Rule | Implementation |
|------|----------------|
| Saldo tidak boleh negatif | Check constraint atau app-level |
| Hutang linked to Penjualan | FK `penjualan_id` di HUTANG |
| Harga snapshot saat transaksi | `harga_satuan` di PENJUALAN_ITEM |
| Pengeluaran pribadi ditandai | `tipe = 'personal'` di KATEGORI |
| Stok minimum alert | `stok_saat_ini < stok_minimum` |

---

## 6. Sync Considerations (PowerSync)

### Sync Tables
- ✅ All tables sync to cloud
- ✅ UUID enables conflict-free merge
- ✅ `updated_at` for change detection

### Local-Only Tables
- `sync_queue` - Pending changes
- `app_settings` - Local preferences

---

*Generated: 2026-01-21*
*Compliant with Rules: #11 (ERD First), #12 (3NF), #13 (Index FK)*
