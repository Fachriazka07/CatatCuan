// DBML for CatatCuan
// Paste directly into dbdiagram.io

Project CatatCuan {
  database_type: 'PostgreSQL'
  Note: 'Generated from catatcuan-admin/catatcuan_schema.sql'
}

Enum user_status {
  active
  inactive
  suspended
}

Enum payment_method {
  tunai
  hutang
}

Enum transaction_status {
  completed
  cancelled
}

Enum expense_category_type {
  business
  personal
}

Enum cash_flow_type {
  masuk
  keluar
}

Enum cash_flow_source {
  penjualan
  pengeluaran
  hutang_bayar
  saldo_awal
}

Enum debt_status {
  belum_lunas
  lunas
  lewat_jatuh_tempo
}

Enum payment_method_debt {
  tunai
  transfer
}

Enum admin_role {
  superadmin
  admin
}

Table ADMIN_USERS {
  id uuid [pk, default: `gen_random_uuid()`]
  email text [not null, unique]
  password_hash text [not null]
  role admin_role [not null]
  created_at timestamptz [default: `now()`]
  last_login_at timestamptz
}

Table APP_CONFIG {
  id uuid [pk, default: `gen_random_uuid()`]
  key text [not null, unique]
  value text
  description text
  updated_at timestamptz [default: `now()`]
  updated_by uuid
}

Table MASTER_KATEGORI_PRODUK {
  id uuid [pk, default: `gen_random_uuid()`]
  nama_kategori text [not null]
  icon text
  sort_order int [default: 0]
  is_active boolean [default: true]
  created_at timestamptz [default: `now()`]
}

Table MASTER_SATUAN {
  id uuid [pk, default: `gen_random_uuid()`]
  nama_satuan text [not null]
  sort_order int [default: 0]
  is_active boolean [default: true]
  created_at timestamptz [default: `now()`]
}

Table SYSTEM_LOGS {
  id uuid [pk, default: `gen_random_uuid()`]
  action text [not null]
  admin_id uuid
  details jsonb
  created_at timestamptz [default: `now()`]
}

Table USERS {
  id uuid [pk, default: `gen_random_uuid()`]
  phone_number text [not null, unique]
  password_hash text [not null]
  status user_status [not null, default: 'active']
  created_at timestamptz [default: `now()`]
  updated_at timestamptz [default: `now()`]
  last_login_at timestamptz
}

Table WARUNG {
  id uuid [pk, default: `gen_random_uuid()`]
  user_id uuid [not null]
  nama_warung text [not null]
  nama_pemilik text
  alamat text
  phone text
  saldo_awal decimal(15,2) [default: 0.00]
  created_at timestamptz [default: `now()`]
  updated_at timestamptz [default: `now()`]
}

Table KATEGORI_PRODUK {
  id uuid [pk, default: `gen_random_uuid()`]
  warung_id uuid [not null]
  nama_kategori text [not null]
  icon text
  sort_order int [default: 0]
  master_kategori_id uuid
  created_at timestamptz [default: `now()`]
}

Table SATUAN_PRODUK {
  id uuid [pk, default: `gen_random_uuid()`]
  warung_id uuid [not null]
  nama_satuan text [not null]
  sort_order int [default: 0]
  master_satuan_id uuid
  created_at timestamptz [default: `now()`]
}

Table PRODUK {
  id uuid [pk, default: `gen_random_uuid()`]
  warung_id uuid [not null]
  kategori_id uuid
  nama_produk text [not null]
  barcode text
  harga_modal decimal(15,2) [not null]
  harga_jual decimal(15,2) [not null]
  stok_saat_ini int [not null, default: 0]
  stok_minimum int [default: 0]
  satuan text [note: 'Text only, not FK to SATUAN_PRODUK']
  is_active boolean [default: true]
  created_at timestamptz [default: `now()`]
  updated_at timestamptz [default: `now()`]
}

Table PELANGGAN {
  id uuid [pk, default: `gen_random_uuid()`]
  warung_id uuid [not null]
  nama text [not null]
  phone text
  alamat text
  total_hutang decimal(15,2) [default: 0.00, note: 'Denormalized field']
  created_at timestamptz [default: `now()`]
  updated_at timestamptz [default: `now()`]
}

Table PENJUALAN {
  id uuid [pk, default: `gen_random_uuid()`]
  warung_id uuid [not null]
  pelanggan_id uuid
  invoice_no text [not null]
  tanggal timestamptz [not null, default: `now()`]
  total_amount decimal(15,2) [not null]
  amount_paid decimal(15,2) [not null]
  amount_change decimal(15,2) [default: 0.00]
  payment_method payment_method [not null]
  status transaction_status [not null, default: 'completed']
  notes text
  created_at timestamptz [default: `now()`]
  updated_at timestamptz [default: `now()`]
  profit decimal(15,2) [default: 0.00, note: 'Profit snapshot per sale']

  indexes {
    (warung_id, invoice_no) [unique]
  }
}

Table PENJUALAN_ITEM {
  id uuid [pk, default: `gen_random_uuid()`]
  penjualan_id uuid [not null]
  produk_id uuid [not null]
  nama_produk text [note: 'Snapshot of product name at transaction time']
  quantity int [not null]
  harga_satuan decimal(15,2) [not null, note: 'Snapshot sale price']
  subtotal decimal(15,2) [not null]
  created_at timestamptz [default: `now()`]
  harga_modal decimal(15,2) [default: 0.00, note: 'Snapshot cost price']
}

Table KATEGORI_PENGELUARAN {
  id uuid [pk, default: `gen_random_uuid()`]
  warung_id uuid [not null]
  nama_kategori text [not null]
  tipe expense_category_type [not null]
  is_system boolean [default: false]
}

Table PENGELUARAN {
  id uuid [pk, default: `gen_random_uuid()`]
  warung_id uuid [not null]
  kategori_id uuid [not null]
  tanggal timestamptz [not null, default: `now()`]
  amount decimal(15,2) [not null]
  keterangan text
  bukti_foto text [note: 'URL to receipt photo']
  created_at timestamptz [default: `now()`]
  updated_at timestamptz [default: `now()`]
}

Table HUTANG {
  id uuid [pk, default: `gen_random_uuid()`]
  warung_id uuid [not null]
  pelanggan_id uuid [not null]
  penjualan_id uuid [unique]
  catatan text
  amount_awal decimal(15,2) [not null]
  amount_terbayar decimal(15,2) [default: 0.00]
  amount_sisa decimal(15,2) [not null]
  tanggal_jatuh_tempo date
  status debt_status [not null]
  created_at timestamptz [default: `now()`]
  updated_at timestamptz [default: `now()`]
}

Table PEMBAYARAN_HUTANG {
  id uuid [pk, default: `gen_random_uuid()`]
  hutang_id uuid [not null]
  tanggal timestamptz [not null, default: `now()`]
  amount decimal(15,2) [not null]
  metode_bayar payment_method_debt [not null]
  notes text
  created_at timestamptz [default: `now()`]
}

Table BUKU_KAS {
  id uuid [pk, default: `gen_random_uuid()`]
  warung_id uuid [not null]
  tanggal timestamptz [not null, default: `now()`]
  tipe cash_flow_type [not null]
  sumber cash_flow_source [not null]
  reference_id uuid [note: 'Logical reference only, not a physical FK']
  reference_type text [note: 'penjualan / pengeluaran / hutang']
  amount decimal(15,2) [not null]
  saldo_setelah decimal(15,2) [not null]
  keterangan text
  created_at timestamptz [default: `now()`]
}

Table LAPORAN_HARIAN {
  id uuid [pk, default: `gen_random_uuid()`]
  warung_id uuid [not null]
  tanggal date [not null]
  total_penjualan decimal(15,2) [default: 0.00]
  total_pengeluaran_bisnis decimal(15,2) [default: 0.00]
  total_pengeluaran_pribadi decimal(15,2) [default: 0.00]
  total_hutang_baru decimal(15,2) [default: 0.00]
  total_hutang_terbayar decimal(15,2) [default: 0.00]
  profit decimal(15,2) [default: 0.00]
  jumlah_transaksi int [default: 0]
  calculated_at timestamptz [default: `now()`, note: 'Pre-calculated daily summary cache']

  indexes {
    (warung_id, tanggal) [unique]
  }
}

Ref: APP_CONFIG.updated_by > ADMIN_USERS.id
Ref: SYSTEM_LOGS.admin_id > ADMIN_USERS.id

Ref: WARUNG.user_id > USERS.id

Ref: KATEGORI_PRODUK.warung_id > WARUNG.id [delete: cascade]
Ref: KATEGORI_PRODUK.master_kategori_id > MASTER_KATEGORI_PRODUK.id [delete: set null]

Ref: SATUAN_PRODUK.warung_id > WARUNG.id [delete: cascade]
Ref: SATUAN_PRODUK.master_satuan_id > MASTER_SATUAN.id [delete: set null]

Ref: PRODUK.warung_id > WARUNG.id [delete: cascade]
Ref: PRODUK.kategori_id > KATEGORI_PRODUK.id [delete: set null]

Ref: PELANGGAN.warung_id > WARUNG.id [delete: cascade]

Ref: PENJUALAN.warung_id > WARUNG.id [delete: cascade]
Ref: PENJUALAN.pelanggan_id > PELANGGAN.id

Ref: PENJUALAN_ITEM.penjualan_id > PENJUALAN.id [delete: cascade]
Ref: PENJUALAN_ITEM.produk_id > PRODUK.id

Ref: KATEGORI_PENGELUARAN.warung_id > WARUNG.id [delete: cascade]
Ref: PENGELUARAN.warung_id > WARUNG.id [delete: cascade]
Ref: PENGELUARAN.kategori_id > KATEGORI_PENGELUARAN.id

Ref: HUTANG.warung_id > WARUNG.id [delete: cascade]
Ref: HUTANG.pelanggan_id > PELANGGAN.id
Ref: PENJUALAN.id - HUTANG.penjualan_id

Ref: PEMBAYARAN_HUTANG.hutang_id > HUTANG.id

Ref: BUKU_KAS.warung_id > WARUNG.id [delete: cascade]

Ref: LAPORAN_HARIAN.warung_id > WARUNG.id [delete: cascade]

TableGroup admin_domain [color: #DDEBF7, note: 'Admin and configuration'] {
  ADMIN_USERS
  APP_CONFIG
  SYSTEM_LOGS
}

TableGroup master_data [color: #E2F0D9, note: 'Reusable master data'] {
  MASTER_KATEGORI_PRODUK
  MASTER_SATUAN
}

TableGroup core_domain [color: #FFF2CC, note: 'User and shop ownership'] {
  USERS
  WARUNG
}

TableGroup product_sales [color: #FCE4D6, note: 'Catalog, customer, and sales'] {
  KATEGORI_PRODUK
  SATUAN_PRODUK
  PRODUK
  PELANGGAN
  PENJUALAN
  PENJUALAN_ITEM
}

TableGroup expense_domain [color: #EADCF8, note: 'Expense tracking'] {
  KATEGORI_PENGELUARAN
  PENGELUARAN
}

TableGroup debt_domain [color: #F4CCCC, note: 'Debt and debt payments'] {
  HUTANG
  PEMBAYARAN_HUTANG
}

TableGroup reporting_cashflow [color: #D9EAD3, note: 'Cash book and daily reports'] {
  BUKU_KAS
  LAPORAN_HARIAN
}
