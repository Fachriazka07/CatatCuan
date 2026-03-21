erDiagram
    direction LR

    ADMIN_USERS {
        uuid id PK
        text email UK
        text password_hash
        admin_role role
        timestamptz created_at
        timestamptz last_login_at
    }

    APP_CONFIG {
        uuid id PK
        text key UK
        text value
        text description
        timestamptz updated_at
        uuid updated_by FK
    }

    SYSTEM_LOGS {
        uuid id PK
        text action
        uuid admin_id FK
        jsonb details
        timestamptz created_at
    }

    MASTER_KATEGORI_PRODUK {
        uuid id PK
        text nama_kategori
        text icon
        int sort_order
        boolean is_active
        timestamptz created_at
    }

    MASTER_SATUAN {
        uuid id PK
        text nama_satuan
        int sort_order
        boolean is_active
        timestamptz created_at
    }

    USERS {
        uuid id PK
        text phone_number UK
        text password_hash
        user_status status
        timestamptz created_at
        timestamptz updated_at
        timestamptz last_login_at
    }

    WARUNG {
        uuid id PK
        uuid user_id FK
        text nama_warung
        text nama_pemilik
        text alamat
        text phone
        decimal saldo_awal
        timestamptz created_at
        timestamptz updated_at
    }

    KATEGORI_PRODUK {
        uuid id PK
        uuid warung_id FK
        text nama_kategori
        text icon
        int sort_order
        uuid master_kategori_id FK
        timestamptz created_at
    }

    SATUAN_PRODUK {
        uuid id PK
        uuid warung_id FK
        text nama_satuan
        int sort_order
        uuid master_satuan_id FK
        timestamptz created_at
    }

    PRODUK {
        uuid id PK
        uuid warung_id FK
        uuid kategori_id FK
        text nama_produk
        text barcode
        decimal harga_modal
        decimal harga_jual
        int stok_saat_ini
        int stok_minimum
        text satuan
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    PELANGGAN {
        uuid id PK
        uuid warung_id FK
        text nama
        text phone
        text alamat
        decimal total_hutang
        timestamptz created_at
        timestamptz updated_at
    }

    PENJUALAN {
        uuid id PK
        uuid warung_id FK
        uuid pelanggan_id FK
        text invoice_no
        timestamptz tanggal
        decimal total_amount
        decimal amount_paid
        decimal amount_change
        payment_method payment_method
        transaction_status status
        text notes
        timestamptz created_at
        timestamptz updated_at
        decimal profit
    }

    PENJUALAN_ITEM {
        uuid id PK
        uuid penjualan_id FK
        uuid produk_id FK
        text nama_produk
        int quantity
        decimal harga_satuan
        decimal subtotal
        timestamptz created_at
        decimal harga_modal
    }

    KATEGORI_PENGELUARAN {
        uuid id PK
        uuid warung_id FK
        text nama_kategori
        expense_category_type tipe
        boolean is_system
    }

    PENGELUARAN {
        uuid id PK
        uuid warung_id FK
        uuid kategori_id FK
        timestamptz tanggal
        decimal amount
        text keterangan
        text bukti_foto
        timestamptz created_at
        timestamptz updated_at
    }

    HUTANG {
        uuid id PK
        uuid warung_id FK
        uuid pelanggan_id FK
        uuid penjualan_id FK
        text catatan
        decimal amount_awal
        decimal amount_terbayar
        decimal amount_sisa
        date tanggal_jatuh_tempo
        debt_status status
        timestamptz created_at
        timestamptz updated_at
    }

    PEMBAYARAN_HUTANG {
        uuid id PK
        uuid hutang_id FK
        timestamptz tanggal
        decimal amount
        payment_method_debt metode_bayar
        text notes
        timestamptz created_at
    }

    BUKU_KAS {
        uuid id PK
        uuid warung_id FK
        timestamptz tanggal
        cash_flow_type tipe
        cash_flow_source sumber
        uuid reference_id
        text reference_type
        decimal amount
        decimal saldo_setelah
        text keterangan
        timestamptz created_at
    }

    LAPORAN_HARIAN {
        uuid id PK
        uuid warung_id FK
        date tanggal
        decimal total_penjualan
        decimal total_pengeluaran_bisnis
        decimal total_pengeluaran_pribadi
        decimal total_hutang_baru
        decimal total_hutang_terbayar
        decimal profit
        int jumlah_transaksi
        timestamptz calculated_at
    }

    ADMIN_USERS ||--o{ APP_CONFIG : updates
    ADMIN_USERS ||--o{ SYSTEM_LOGS : writes

    USERS ||--o{ WARUNG : owns

    MASTER_KATEGORI_PRODUK ||--o{ KATEGORI_PRODUK : template_for
    MASTER_SATUAN ||--o{ SATUAN_PRODUK : template_for

    WARUNG ||--o{ KATEGORI_PRODUK : has
    WARUNG ||--o{ SATUAN_PRODUK : has
    WARUNG ||--o{ PRODUK : has
    KATEGORI_PRODUK o|--o{ PRODUK : categorizes

    WARUNG ||--o{ PELANGGAN : has
    WARUNG ||--o{ PENJUALAN : records
    PELANGGAN o|--o{ PENJUALAN : makes
    PENJUALAN ||--|{ PENJUALAN_ITEM : contains
    PRODUK ||--o{ PENJUALAN_ITEM : sold_as

    WARUNG ||--o{ KATEGORI_PENGELUARAN : has
    WARUNG ||--o{ PENGELUARAN : records
    KATEGORI_PENGELUARAN ||--o{ PENGELUARAN : categorizes

    WARUNG ||--o{ HUTANG : records
    PELANGGAN ||--o{ HUTANG : owes
    PENJUALAN ||--o| HUTANG : creates
    HUTANG ||--o{ PEMBAYARAN_HUTANG : paid_by

    WARUNG ||--o{ BUKU_KAS : tracks
    WARUNG ||--o{ LAPORAN_HARIAN : generates
