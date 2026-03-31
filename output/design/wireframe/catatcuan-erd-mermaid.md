erDiagram
    direction TB

    %% ==================== ADMIN & SISTEM ====================
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

    %% ==================== MASTER DATA ====================
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

    %% ==================== USER, WARUNG, DEVICE ====================
    USERS {
        uuid id PK
        text phone_number UK
        text password_hash
        user_status status
        timestamptz created_at
        timestamptz updated_at
        timestamptz last_login_at
    }

    MOBILE_DEVICE_TOKENS {
        uuid id PK
        uuid user_id FK
        text device_token UK
        text platform
        text device_label
        boolean is_active
        timestamptz last_seen_at
        text last_error
        timestamptz created_at
        timestamptz updated_at
    }

    USER_NOTIFICATION_PREFERENCES {
        uuid user_id PK
        boolean push_enabled
        boolean sms_enabled
        boolean due_date_reminder
        boolean low_stock_alert
        boolean daily_reminder
        timestamptz updated_at
    }

    PASSWORD_RESET_OTPS {
        uuid id PK
        uuid user_id FK
        text phone_number
        text code_hash
        text channel
        timestamptz expires_at
        timestamptz used_at
        int attempt_count
        timestamptz sent_at
        timestamptz created_at
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

    NOTIFICATION_LOGS {
        uuid id PK
        uuid user_id FK
        uuid warung_id FK
        text channel
        text notification_type
        text title
        text body
        jsonb payload
        text provider_message_id
        text status
        text error_message
        timestamptz sent_at
        timestamptz created_at
    }

    %% ==================== KATALOG & PELANGGAN ====================
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

    %% ==================== TRANSAKSI PENJUALAN ====================
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

    %% ==================== PENGELUARAN ====================
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

    %% ==================== HUTANG / PIUTANG ====================
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

    %% ==================== KAS & LAPORAN ====================
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

    %% ==================== RELASI ADMIN & SISTEM ====================
    ADMIN_USERS o|--o{ APP_CONFIG : updates
    ADMIN_USERS o|--o{ SYSTEM_LOGS : writes

    %% ==================== RELASI USER & WARUNG ====================
    USERS ||--o{ MOBILE_DEVICE_TOKENS : uses
    USERS ||--o| USER_NOTIFICATION_PREFERENCES : has
    USERS ||--o{ PASSWORD_RESET_OTPS : requests
    USERS ||--o{ WARUNG : owns
    USERS o|--o{ NOTIFICATION_LOGS : receives
    WARUNG o|--o{ NOTIFICATION_LOGS : sends_for

    %% ==================== RELASI MASTER & KATALOG ====================
    MASTER_KATEGORI_PRODUK o|--o{ KATEGORI_PRODUK : templates
    MASTER_SATUAN o|--o{ SATUAN_PRODUK : templates

    WARUNG ||--o{ KATEGORI_PRODUK : has
    WARUNG ||--o{ SATUAN_PRODUK : has
    WARUNG ||--o{ PRODUK : has
    KATEGORI_PRODUK o|--o{ PRODUK : categorizes

    WARUNG ||--o{ PELANGGAN : has

    %% ==================== RELASI TRANSAKSI ====================
    WARUNG ||--o{ PENJUALAN : records
    PELANGGAN o|--o{ PENJUALAN : makes
    PENJUALAN ||--|{ PENJUALAN_ITEM : contains
    PRODUK ||--o{ PENJUALAN_ITEM : sold_as

    WARUNG ||--o{ KATEGORI_PENGELUARAN : has
    WARUNG ||--o{ PENGELUARAN : records
    KATEGORI_PENGELUARAN ||--o{ PENGELUARAN : categorizes

    %% ==================== RELASI HUTANG / PIUTANG ====================
    WARUNG ||--o{ HUTANG : records
    PELANGGAN ||--o{ HUTANG : owes
    PENJUALAN o|--o| HUTANG : originates
    HUTANG ||--o{ PEMBAYARAN_HUTANG : paid_by

    %% ==================== RELASI KAS & LAPORAN ====================
    WARUNG ||--o{ BUKU_KAS : tracks
    WARUNG ||--o{ LAPORAN_HARIAN : summarizes
    
    %% Catatan:
    %% - PRODUK.satuan masih berupa text, bukan foreign key ke SATUAN_PRODUK.
    %% - BUKU_KAS.reference_id dan reference_type adalah referensi logis, bukan foreign key fisik.
    %% - NOTIFICATION_LOGS.user_id, NOTIFICATION_LOGS.warung_id, APP_CONFIG.updated_by,
    %%   dan HUTANG.penjualan_id bersifat opsional sesuai schema SQL.
