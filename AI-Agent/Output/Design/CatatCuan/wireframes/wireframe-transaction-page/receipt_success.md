# Wireframe: Receipt & Success

## Overview

- **Priority:** P0 (Core Feature)
- **URL:** `/transaksi/receipt`
- **User Story:** Sebagai owner, setelah transaksi berhasil, saya ingin melihat struk detailnya dan memiliki opsi untuk menyimpannya saja atau mencetaknya via printer Bluetooth. Nama warung harus dinamis.

## Layout Structure

```text
+--------------------------------------------------+
| [Header - Gradient Green: #13B158 to #3A9B6B]    |
|  < Beranda           Transaksi Berhasil          |
+--------------------------------------------------+
| [Success Animation / Icon]                       |
|         ✅ Pembayaran Sukses!                    |
+--------------------------------------------------+
| [Receipt Preview Card]                           |
|  ======================================          |
|         [ NAMA WARUNG DARI DB ]                  |
|      [ ALAMAT WARUNG DARI DB / KOSONG ]          |
|  ======================================          |
|  No: TRX-0001                                    |
|  Tgl: 25 Feb 2026 09:15                          |
|  Kasir: Admin                                    |
|  --------------------------------------          |
|  Kopi (x2)                     Rp 10.000         |
|  Beras 5kg (x1)                Rp 65.000         |
|  --------------------------------------          |
|  Subtotal:                     Rp 75.000         |
|  Diskon:                      -Rp  5.000         |
|  Total:                        Rp 70.000         |
|  --------------------------------------          |
|                                                  |
|   -- JIKA TUNAI --                               |
|  Tunai:                        Rp 100.000        |
|  Kembalian:                    Rp  30.000        |
|                                                  |
|   -- JIKA KASBON / HUTANG --                     |
|  Pelanggan:                    Paijo             |
|  DP / Uang Muka:               Rp   0            |
|  Sisa Hutang:                  Rp 70.000         |
|                                                  |
|  ======================================          |
|             Terima Kasih!                        |
+--------------------------------------------------+
|                                                  |
| [Action Buttons]                                 |
|                                                  |
|  [        CETAK STRUK (Icon Printer)      ]      |
|  [      SELESAI (Simpan & Kembali POS)    ]      |
|                                                  |
+--------------------------------------------------+
```

## Elements & Data Mapping

- **Receipt Preview**: Menampilkan simulasi struk asli yang akan di print.
  - **IDENTITAS WARUNG**: Nama Toko / Alamat di-fetch dinamis dari Data Cache (`_cache.warungData['nama_warung']`).
  - Isinya bergantung apakah transaksinya **Tunai** atau **Kasbon/Hutang**.
- **Action Buttons**:
  - **Cetak Struk**: Menggunakan button warna Secondary Kuning `#F8BD00`. Akan trigger perintah print bluetooth.
  - **Selesai / Simpan Aja**: Menggunakan Outlined button atau Text Button warna hijau primary. Menutup layar dan mereset halaman Kasir ke state awal.

## States

### Loading State (Menyimpan)

- Saat tombol BAYAR ditekan dari halaman sebelumnya, halaman ini tampil loading menyimpannya.

### No Printer State

- Bila dicetak tapi printer tidak terhubung, munculkan SnackBar error.

## Interactions

1. `Click` [CETAK STRUK] -> Hubungkan bluetooth -> Print data text yang disusun ke `blue_thermal_printer`.
2. `Click` [SELESAI] -> `context.go('/transaksi/pos')` dengan state keranjang yang telah di-clear.
