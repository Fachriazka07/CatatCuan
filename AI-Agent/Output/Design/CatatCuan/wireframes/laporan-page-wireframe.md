# CatatCuan - Laporan Page Wireframe

**Version:** 1.0  
**Date:** 2026-03-25  
**Fidelity:** Mid-Fi (Layout + UX behavior)  
**Platform:** Mobile-First (Flutter)  
**Route:** `/laporan`

---

## 1. Overview

### Purpose
Halaman `Laporan` diposisikan sebagai pusat rekap dan export dokumen bisnis.  
Halaman ini **bukan** tempat analitik visual atau chart berat. Chart, trend analysis, dan insight cepat disiapkan untuk fitur `Stats` di bottom navbar.

### Primary Goals
- Menampilkan ringkasan laporan berdasarkan periode
- Memudahkan user memilih jenis laporan yang ingin diexport
- Menyediakan angka inti yang siap dibaca owner warung
- Menyediakan export ke `Excel` dan `PDF`

### UX Positioning
- `Laporan` = rekap, dokumen, export, siap dibagikan
- `Stats` = insight cepat, analitik, trend, visual comparison

---

## 2. Design Alignment With Existing Mobile Pages

Wireframe ini disusun agar konsisten dengan halaman mobile yang sudah ada:

- Header hijau solid / gradient seperti `Pengeluaran`, `Buku Kas`, `Pelanggan`
- Background page abu muda `#F8F9FA`
- Card putih dengan border hijau muda `#D1EDD8`
- Aksen utama hijau `#13B158`
- Aksen highlight emas `#EAA220`
- Typography bergaya `Poppins`
- Radius cenderung medium-large `10-20dp`
- Pola section vertikal dengan spacing lega
- CTA jelas, sederhana, dan mudah disentuh

### Visual Tone
- Rapi
- Formal ringan
- Mudah dipindai owner warung
- Tidak terasa seperti halaman dashboard chart

---

## 3. Information Architecture

Urutan konten di halaman:

1. Header
2. Periode laporan
3. Ringkasan utama
4. Ringkasan angka pendukung
5. Jenis laporan yang bisa diexport
6. Produk terlaris
7. Export action

---

## 4. Main Layout Structure

```text
+------------------------------------------+
|  Laporan                           [X]   |
+------------------------------------------+
|                                          |
|  PERIODE LAPORAN                         |
|  [ Minggu Ini v ]                        |
|  [ 18 Mar 2026 - 25 Mar 2026 ]           |
|                                          |
|  LABA BERSIH                             |
|  +------------------------------------+  |
|  | Rp 875.000                         |  |
|  | Penjualan - modal - pengeluaran    |  |
|  | Status: Naik / Stabil / Turun      |  |
|  +------------------------------------+  |
|                                          |
|  +------------------+ +----------------+ |
|  | Penjualan        | | Pengeluaran    | |
|  | Rp 2.500.000     | | Rp 625.000     | |
|  +------------------+ +----------------+ |
|                                          |
|  +------------------+ +----------------+ |
|  | Profit Penjualan | | Uang Kas Masuk | |
|  | Rp 1.500.000     | | Rp 1.250.000   | |
|  +------------------+ +----------------+ |
|                                          |
|  JENIS LAPORAN                           |
|  +------------------------------------+  |
|  | Ringkasan Keuangan            >     | |
|  | Omzet, profit, expense, neto        | |
|  +------------------------------------+  |
|  | Laporan Penjualan             >     | |
|  | Daftar transaksi dan total jual     | |
|  +------------------------------------+  |
|  | Laporan Pengeluaran           >     | |
|  | Daftar biaya dan kategori           | |
|  +------------------------------------+  |
|  | Laporan Buku Kas              >     | |
|  | Mutasi kas masuk dan keluar         | |
|  +------------------------------------+  |
|  | Laporan Hutang/Piutang        >     | |
|  | Tagihan, pembayaran, sisa           | |
|  +------------------------------------+  |
|                                          |
|  PRODUK TERLARIS                         |
|  +------------------------------------+  |
|  | 1. Indomie Goreng       150 terjual | |
|  | 2. Aqua 600ml            85 terjual | |
|  | 3. Rokok Marlboro        42 terjual | |
|  | 4. Telur 1 Kg            31 terjual | |
|  | 5. Kopi Sachet           28 terjual | |
|  +------------------------------------+  |
|                                          |
|  EXPORT                                  |
|  +------------------+ +----------------+ |
|  | Export Excel     | | Export PDF     | |
|  +------------------+ +----------------+ |
|                                          |
+------------------------------------------+
```

---

## 5. Section Breakdown

### 5.1 Header

```text
+------------------------------------------+
|  Laporan                           [X]   |
+------------------------------------------+
```

**Behavior**
- Mengikuti pola existing page: title kiri, close button bulat putih di kanan
- Bisa pakai back arrow jika ingin konsisten dengan route push biasa
- Tinggi header sekitar `100-110dp`

**Style**
- Background hijau
- Teks putih
- Tombol close berbentuk lingkaran putih dengan icon hitam

---

### 5.2 Period Section

```text
PERIODE LAPORAN
[ Minggu Ini v ]
[ 18 Mar 2026 - 25 Mar 2026 ]
```

**Options**
- Hari ini
- Minggu ini
- Bulan ini
- Custom

**Behavior**
- Tap dropdown periode membuka bottom sheet atau popup menu
- Jika `Custom`, user lanjut ke date range picker
- Setelah periode berubah, semua ringkasan dan daftar ter-update

**Design Notes**
- Label section uppercase seperti halaman `Pengeluaran`
- Selector tampil seperti pill/card putih border hijau muda
- Range tanggal tampil sebagai supporting label di bawah selector

---

### 5.3 Main Summary Card

```text
LABA BERSIH
+--------------------------------------+
| Rp 875.000                           |
| Penjualan - modal - pengeluaran      |
| Status: Naik / Stabil / Turun        |
+--------------------------------------+
```

**Purpose**
- Menjadi fokus utama halaman
- Angka pertama yang dilihat user saat membuka laporan

**Contents**
- Nilai laba bersih periode
- Rumus singkat agar mudah dipahami
- Optional status label:
  - `Naik`
  - `Stabil`
  - `Turun`

**Design Notes**
- Card putih utama
- Nilai besar dengan emphasis hijau tua
- Label kecil abu
- Status kecil dengan chip hijau / abu / merah

---

### 5.4 Supporting Summary Grid

```text
+------------------+ +----------------+
| Penjualan        | | Pengeluaran    |
| Rp 2.500.000     | | Rp 625.000     |
+------------------+ +----------------+

+------------------+ +----------------+
| Profit Penjualan | | Uang Kas Masuk |
| Rp 1.500.000     | | Rp 1.250.000   |
+------------------+ +----------------+
```

**Recommended Metrics**
- Penjualan
- Pengeluaran
- Profit Penjualan
- Uang Kas Masuk

**Alternative 4th Card**
Jika nanti dirasa lebih berguna, `Uang Kas Masuk` bisa diganti:
- `Uang Kas Keluar`
- `Jumlah Transaksi`
- `Piutang Belum Lunas`

**Design Notes**
- Grid 2x2 seperti pola stats di Home
- Card lebih kecil dari main summary
- Ikon opsional, tapi tidak wajib
- Fokus ke angka dan label, bukan dekorasi

---

### 5.5 Report Type List

```text
JENIS LAPORAN
+--------------------------------------+
| Ringkasan Keuangan              >    |
| Omzet, profit, expense, neto         |
+--------------------------------------+
| Laporan Penjualan               >    |
| Daftar transaksi dan total jual      |
+--------------------------------------+
| Laporan Pengeluaran             >    |
| Daftar biaya dan kategori            |
+--------------------------------------+
| Laporan Buku Kas                >    |
| Mutasi kas masuk dan keluar          |
+--------------------------------------+
| Laporan Hutang/Piutang          >    |
| Tagihan, pembayaran, sisa            |
+--------------------------------------+
```

**Purpose**
- Menjelaskan output export yang tersedia
- Menjadi titik pilih jenis laporan sebelum export

**Interaction Recommendation**
- Satu item bisa aktif sebagai selected state
- Default selected: `Ringkasan Keuangan`

**Selected State**
- Border hijau lebih tegas
- Background hijau sangat muda
- Ada check kecil atau highlight sisi kiri

---

### 5.6 Best Seller Section

```text
PRODUK TERLARIS
+--------------------------------------+
| 1. Indomie Goreng       150 terjual  |
| 2. Aqua 600ml            85 terjual  |
| 3. Rokok Marlboro        42 terjual  |
| 4. Telur 1 Kg            31 terjual  |
| 5. Kopi Sachet           28 terjual  |
+--------------------------------------+
```

**Purpose**
- Menambah konteks laporan tanpa perlu chart
- Tetap informatif dan cocok untuk export-oriented page

**Behavior**
- Menampilkan top 5 produk berdasarkan quantity terjual pada periode aktif
- Jika tidak ada penjualan, section berubah menjadi empty state sederhana

**Design Notes**
- List putih dengan divider tipis
- Rank kiri, nama produk di tengah, qty di kanan
- Bisa diberi badge kecil `Terlaris`

---

### 5.7 Export Section

```text
EXPORT
+------------------+ +----------------+
| Export Excel     | | Export PDF     |
+------------------+ +----------------+
```

**Purpose**
- CTA utama halaman
- Hanya aktif jika jenis laporan sudah dipilih

**Behavior**
- Tap `Export Excel` membuka konfirmasi export
- Tap `Export PDF` membuka konfirmasi export
- Setelah proses selesai:
  - tampil success toast
  - bisa lanjut share / save / preview

**Design Notes**
- Dua tombol sejajar
- Tombol `Excel` bisa outline hijau
- Tombol `PDF` bisa filled emas atau hijau agar terasa penting

---

## 6. Bottom Sheet - Select Period

Digunakan saat user tap selector periode.

```text
+------------------------------------------+
|              Pilih Periode               |
|------------------------------------------|
| ( ) Hari ini                             |
| (o) Minggu ini                           |
| ( ) Bulan ini                            |
| ( ) Custom                               |
|                                          |
|                 [ Terapkan ]             |
+------------------------------------------+
```

**Behavior**
- Jika pilih `Custom`, buka date range picker setelah tap `Terapkan`
- Sheet bisa ditutup swipe down atau close action

---

## 7. Bottom Sheet - Export Confirmation

Digunakan sebelum file dibuat.

```text
+------------------------------------------+
|            Export Laporan                |
|------------------------------------------|
| Jenis Laporan : Ringkasan Keuangan       |
| Periode       : Minggu Ini               |
| Format        : PDF                      |
|                                          |
| File akan berisi ringkasan laporan       |
| sesuai periode yang dipilih.             |
|                                          |
|      [ Batal ]       [ Export Sekarang ] |
+------------------------------------------+
```

**Optional Add-on**
- Checkbox `Sertakan daftar produk terlaris`
- Checkbox `Sertakan detail transaksi`

---

## 8. States

### 8.1 Loading State

```text
+------------------------------------------+
|  Laporan                           [X]   |
+------------------------------------------+
|  [ PERIODE SKELETON ]                    |
|                                          |
|  +------------------------------------+  |
|  |           SKELETON CARD            |  |
|  +------------------------------------+  |
|                                          |
|  +------------------+ +----------------+ |
|  |    SKELETON      | |   SKELETON     | |
|  +------------------+ +----------------+ |
|                                          |
|  +------------------+ +----------------+ |
|  |    SKELETON      | |   SKELETON     | |
|  +------------------+ +----------------+ |
|                                          |
|  [ LIST SKELETON ]                       |
|  [ LIST SKELETON ]                       |
+------------------------------------------+
```

**Recommendation**
- Gunakan skeleton ringan, bukan spinner penuh
- Jangan kosong total karena halaman laporan cukup data-heavy

---

### 8.2 Empty State

```text
+------------------------------------------+
|  Laporan                           [X]   |
+------------------------------------------+
|  PERIODE LAPORAN                         |
|  [ Bulan Ini v ]                         |
|                                          |
|            [ icon dokumen ]              |
|         Belum ada data laporan           |
|  Coba pilih periode lain atau mulai      |
|  catat transaksi dan pengeluaran.        |
|                                          |
|         [ Export Disabled ]              |
+------------------------------------------+
```

**When Used**
- Tidak ada penjualan, pengeluaran, atau data kas pada periode terpilih

---

### 8.3 Best Seller Empty State

```text
PRODUK TERLARIS
+--------------------------------------+
| Belum ada produk terjual             |
| pada periode ini                     |
+--------------------------------------+
```

---

### 8.4 Export Success State

```text
[Toast]
Laporan PDF berhasil dibuat
```

**Recommendation**
- Toast singkat
- Bisa ditambah action `Lihat File` atau `Bagikan`

---

## 9. Components Breakdown

| Component | Description |
|----------|-------------|
| Header | Title `Laporan` + close/back button |
| Period Selector | Dropdown periode + rentang tanggal aktif |
| Main Summary Card | Highlight laba bersih |
| Summary Grid | 2x2 kartu ringkasan angka |
| Report Type List | Pilihan jenis laporan export |
| Best Seller List | Top 5 produk terjual |
| Export Buttons | CTA `Excel` dan `PDF` |
| Export Confirmation Sheet | Konfirmasi sebelum generate file |

---

## 10. Data Mapping Recommendation

### Main Numbers
- `Penjualan` = sum `PENJUALAN.total_amount`
- `Profit Penjualan` = sum `PENJUALAN.profit`
- `Pengeluaran` = sum `PENGELUARAN.amount`
- `Laba Bersih` = sum `PENJUALAN.profit` - sum `PENGELUARAN.amount`

### Cash Metrics
- `Uang Kas Masuk` = sum `BUKU_KAS.amount` where `tipe = masuk`
- `Uang Kas Keluar` = sum `BUKU_KAS.amount` where `tipe = keluar`

### Best Seller
- Source: `PENJUALAN_ITEM`
- Aggregate by:
  - `produk_id`
  - `nama_produk`
- Order by total `quantity` desc

### Debt Report
- Source:
  - `HUTANG`
  - `PEMBAYARAN_HUTANG`

---

## 11. Interaction Flow

1. User buka menu `Laporan` dari Home
2. Halaman load default periode `Minggu ini`
3. User lihat ringkasan angka utama
4. User pilih jenis laporan yang ingin diexport
5. User tap `Export Excel` atau `Export PDF`
6. App tampilkan bottom sheet konfirmasi
7. App generate file
8. App tampilkan success feedback

---

## 12. UX Rules For This Page

- Tidak memakai chart
- Satu fokus utama: rekap + export
- Angka utama harus mudah discan dalam 3 detik
- Periode harus selalu terlihat jelas
- Export action harus berada di bawah setelah user paham isi laporan
- Gunakan istilah keuangan yang konsisten dengan app:
  - `Penjualan`
  - `Pengeluaran`
  - `Profit Penjualan`
  - `Laba Bersih`
  - `Buku Kas`
  - `Hutang/Piutang`

---

## 13. Future Extension

Ruang pengembangan berikutnya tanpa mengubah fondasi layout:

- Tambah preview isi laporan sebelum export
- Tambah filter `hari ini / minggu ini / bulan ini / custom`
- Tambah badge perbandingan periode lalu
- Tambah section `Kategori Pengeluaran Terbesar`
- Tambah section `Pelanggan Paling Sering Belanja`
- Tambah share action setelah file selesai dibuat

---

## 14. Implementation Notes

### Recommended V1 Scope
- Period selector
- Main summary card
- 4 summary cards
- Report type selection
- Best seller list
- Export buttons

### Explicit Non-Scope For This Page
- Chart batang
- Pie chart
- Trend graph
- Statistik real-time yang kompleks

Alasan: fitur-fitur tersebut lebih cocok diletakkan di halaman `Stats`.

---

## 15. Final Direction

Halaman `Laporan` CatatCuan harus terasa seperti:
- ringkas
- formal
- mudah dipahami owner warung
- siap dijadikan dokumen

Bukan seperti analytics dashboard penuh visual, tetapi seperti halaman rekap yang siap diubah menjadi file `Excel` atau `PDF`.
