# Wireframe: POS / Kasir

## Overview

- **Priority:** P0 (Core Feature)
- **URL:** `/transaksi/pos`
- **Design System:** Konsisten dengan halaman `CustomerListPage` dan `ProductListPage` (Gradient Hijau, Poppins, Card putih rounded border hijau muda).

## Layout Structure

```text
+--------------------------------------------------+
| [Header - Gradient Green: #13B158 to #3A9B6B]    |
|  < Back     Penjualan (Kasir)                    |
+--------------------------------------------------+
| [Search Bar Area - Elevated White Container]     |
|  [🔍 Cari Produk...]   [Filter Icon #1A237E]      |
+--------------------------------------------------+
| [Category Chips - Scrollable Horizontal]         |
|  [Semua]  [☕ Minuman]  [🍪 Cemilan]  [🚬 Rokok]   |
+--------------------------------------------------+
| [Product Grid Area - 2 Columns]                  |
|                                                  |
| +--------------------+  +--------------------+   |
| | [Ikon: Kopi.png]   |  | [Ikon: Rokok.png]  |   |
| |                    |  |                    |   |
| | Kopi Hitam         |  | Sampoerna Mild     |   |
| | Stok: 10           |  | Stok: 5            |   |
| | Rp 5.000           |  | Rp 30.000          |   |
| +--------------------+  +--------------------+   |
|                                                  |
+--------------------------------------------------+
| [Floating Action Button - + Tambah Produk]       |
|  (Warna Primary Hijau, nempel di kanan bawah,    |
|   di atas Bottom Cart Bar)                       |
+--------------------------------------------------+
| [Bottom Cart Bar - Sticky at Bottom]             |
|  (Warna Secondary Yellow: #F8BD00)               |
|  Total: Rp 35.000                                |
|  2 Macam Barang         [ LANJUT BAYAR > ]       |
+--------------------------------------------------+
```

## Elements & Design Mapping

- **Header & Search Bar**: Sama persis dengan `product_list.dart`. (Tertutup gradient header hijau CatatCuan).
- **Grid Item Card**:
  - Warna card putih dengan border warna `#D1EDD8`.
  - **Image**: **TIDAK MENGGUNAKAN GAMBAR FOTO**. Menggunakan kotak biru muda `#F2F6FF` ukuran 60x60 dengan `Image.asset` berupa icon kategori product (Contoh: `Minuman.png`, `Rokok.png`, dll).
- **Floating Action Button (FAB - Tambah Produk)**:
  - Solusi untuk "Produk tidak ada saat dicari".
  - Tombol `+` ini akan membuka **Bottom Sheet Form** `add_product` atau men-navigasi ke halaman `/produk/add` (dan _return_ kembali ke halaman Kasir setelah disave) sehingga user tidak perlu bolak-balik halaman utama.
- **Bottom Cart Bar**: Muncul `AnimatedPositioned` / `Visibility` jika total belanja > 0. Dibuat eye-catching (warna kuning `#F8BD00`).

## States

### Empty State (Kosong)

```text
+--------------------------------------------------+
| [Header Gradient]                                |
+--------------------------------------------------+
|  [Search Area]                                   |
+--------------------------------------------------+
|                                                  |
|                  📦                              |
|          Produk tidak ditemukan                  |
|          [+ Tambah Produk Baru]                  |
+--------------------------------------------------+
```

### Interactions

1. `Tap Grid Item` -> Angka di keranjang bottom bar ter-update otomatis secara _reactive_.
2. `Tap Kategori / Chip` -> Chip yang terpilih berubah warna menjadi Hijau Primary, sisanya Abu-Abu/Outline. Grid me-render produk di kategori tersebut.
3. `Tap [Lanjut Bayar]` -> Pindah halaman ke`/transaksi/checkout`.
4. `Tap [+] FAB Tambah Produk` -> Buka Dialog/Bottom Sheet/Halaman untuk tambah produk "on-the-fly". Setelah tersimpan, produk langsung muncul di grid dan siap di-tap.
