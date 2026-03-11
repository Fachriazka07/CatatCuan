# Wireframe: Checkout & Payment

## Overview

- **Priority:** P0 (Core Feature)
- **URL:** `/transaksi/checkout`
- **Design System:** Menggunakan `Scaffold` background `#F8F9FA` dengan Header Gradient Hijau CatatCuan. Container form berwarna putih dengan border `#D1EDD8` + Drop Shadow ringan.

## Layout Structure

```text
+--------------------------------------------------+
| [Header - Gradient Green: #13B158 to #3A9B6B]    |
|  < Kembali           Pembayaran                  |
+--------------------------------------------------+
|                                                  |
| [Container 1: List Keranjang Belanja]            |
| +----------------------------------------------+ |
| | [Icon Minuman]  Kopi Hitam           Rp10.000| |
| |                 (-)  [2]  (+)       (5k/pcs) | |
| | -------------------------------------------- | |
| | [Icon Sembako]  Beras 5kg            Rp65.000| |
| |                 (-)  [1]  (+)      (65k/pcs) | |
| |                                              | |
| | [+ Tambah Produk (Warna Teks Hijau)]         | |
| +----------------------------------------------+ |
|                                                  |
| [Container 2: Ringkasan Biaya]                   |
| +----------------------------------------------+ |
| |  Subtotal                           Rp 75.000| |
| |  Diskon [Input Rp]                 -Rp  5.000| |
| | -------------------------------------------- | |
| |  Total Tagihan                      Rp 70.000| |
| +----------------------------------------------+ |
|                                                  |
| [Container 3: Tipe Pembayaran]                   |
| +----------------------------------------------+ |
| |  Pilih Pembayaran:                           | |
| |  [ Button: TUNAI ]  [ Button: HUTANG ]       | |
| |                                              | |
| |  -- JIKA TUNAI TERPILIH --                   | |
| |  Uang Diterima                               | |
| |  [ Input Nominal: Rp 100.000 ]               | |
| |                                              | |
| |  Kembalian                                   | |
| |  Rp 30.000  (Teks Warna Hijau/Kuning)        | |
| |                                              | |
| |  -- JIKA HUTANG TERPILIH --                  | |
| |  Pilih Pelanggan [Dropdown/Search Pelanggan] | |
| |  Uang Muka (DP)  [Input Nominal Rp 0]        | |
| |  Sisa Hutang     : Rp 70.000                 | |
| |  Jatuh Tempo     [Input Tanggal]             | |
| +----------------------------------------------+ |
|                                                  |
+--------------------------------------------------+
| [Bottom Action - Sticky at Bottom]               |
|  [        BAYAR SEKARANG (Hijau Primary)  ]      |
+--------------------------------------------------+
```

## Elements & Design Mapping

- **Containers**: Mengadopsi struktur container dari file `add_customer.dart` atau `add_product.dart`.
  - Warna background putih.
  - Radius modern (misal `borderRadius: BorderRadius.circular(20)`).
  - Border halus `#D1EDD8`.
- **List Keranjang Item**:
  - Menggunakan Icon kategori, BUKAN foto. Ikon dibungkus rounded box warna `#F2F6FF`.
  - Tombol `(+)` dan `(-)` punya styling border standar. Jika kuantitas turun menjadi 0, field dihapus dari keranjang.
- **Input Data**:
  - Bentuk field `TextFormField` mengambil stye "INPUT..." yang kita gunakan di seluruh UI. Lebar border 1.5, focused color `AppTheme.primary`.
- **Pilihan Pembayaran**:
  - Memakai desain 2 tombol Horizontal (Segmented Control / Radio Buttons rapi).

## Interactions

1. **User Ubah QTY**: Subtotal dan Total Tagihan terhitung otomatis secara riil (reaktif).
2. **User Isi Uang Diterima**: Text/Warna tulisan "Kembalian" muncul langsung. Jika uang kurang, field mungkin merah.
3. **Klik [Bayar Sekarang]**: Menjalankan aksi Supabase untuk membuat row di `PENJUALAN` dan me-redirect layar menuju Resi.
