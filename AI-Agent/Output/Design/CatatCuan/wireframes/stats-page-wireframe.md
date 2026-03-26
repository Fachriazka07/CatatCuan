# CatatCuan - Stats Page Wireframe

**Version:** 1.0  
**Date:** 2026-03-25  
**Fidelity:** Mid-Fi (Layout + UX behavior)  
**Platform:** Mobile-First (Flutter)  
**Route:** `/stats`

---

## 1. Overview

### Purpose
Halaman `Stats` diposisikan sebagai pusat analitik cepat untuk owner warung.  
Halaman ini membantu user membaca performa usaha, tren transaksi, pola kas, dan sinyal penting yang butuh perhatian.

### Primary Goals
- Menampilkan insight usaha secara cepat
- Mempermudah user membaca tren penjualan, profit, dan cashflow
- Menyediakan visual yang lebih hidup dibanding `Laporan`
- Membantu pengambilan keputusan harian dan mingguan

### UX Positioning
- `Laporan` = dokumen, rekap, export, siap dibagikan
- `Stats` = visual analytics, insight cepat, trend, perbandingan periode

### Product Role
Karena `Stats` ada di bottom navbar, halaman ini harus:
- cepat dimengerti
- tidak terasa berat
- informatif dalam sekali scroll
- lebih visual daripada `Laporan`

---

## 2. Design Alignment With Existing Mobile Pages

Wireframe ini disusun agar tetap konsisten dengan mobile app CatatCuan yang sudah ada:

- Header hijau seperti page utama lain
- Background abu muda `#F8F9FA`
- Surface putih dengan border hijau muda `#D1EDD8`
- Aksen hijau `#13B158` untuk performa positif
- Aksen merah `#DC2626` untuk penurunan / beban
- Aksen emas `#EAA220` untuk highlight insight penting
- Typography tetap `Poppins`
- Radius medium-large agar sejalan dengan `Home`, `Buku Kas`, `Pengeluaran`

### Visual Tone
- Lebih hidup daripada `Laporan`
- Lebih visual, tapi tetap rapi
- Fokus ke scan cepat, bukan pembacaan dokumen

---

## 3. Information Architecture

Urutan konten di halaman:

1. Header
2. Quick period filters
3. KPI summary
4. Main trend chart
5. Cashflow chart
6. Insight cards
7. Best performer section
8. Non-operational note section

---

## 4. Operational Scope Rule

Supaya halaman `Stats` tidak membingungkan, metrik utama harus fokus ke **operasional warung / UMKM**.

### Masuk ke Stats utama
- Penjualan
- Profit penjualan
- Pengeluaran usaha
- Kas masuk / keluar usaha
- Hutang/piutang yang memang terkait usaha
- Produk terlaris
- Jumlah transaksi

### Tidak masuk ke KPI utama
- Catatan pribadi
- Transaksi non-operasional
- pengeluaran rumah tangga
- hutang yang tidak terkait usaha

### Cara menampilkannya
Jika data non-operasional memang ada di sistem, tampilkan terpisah sebagai:
- `Catatan Non-Operasional`
- `Transaksi Di Luar Usaha`
- `Tidak dihitung ke statistik inti`

Jadi user tetap tahu datanya ada, tapi tidak mengacaukan insight bisnis warung.

---

## 5. Main Layout Structure

```text
+------------------------------------------+
|  Stats                             [..]  |
+------------------------------------------+
|                                          |
|  PERIODE                                 |
|  [ 7 Hari ] [ 30 Hari ] [ Bulan Ini ]    |
|  [ Custom ]                              |
|                                          |
|  +------------------+ +----------------+ |
|  | Omzet            | | Profit         | |
|  | Rp 2.500.000     | | Rp 875.000     | |
|  | +12% vs lalu     | | +8% vs lalu    | |
|  +------------------+ +----------------+ |
|                                          |
|  +------------------+ +----------------+ |
|  | Pengeluaran      | | Net Cashflow   | |
|  | Rp 625.000       | | Rp 1.120.000   | |
|  | -4% vs lalu      | | +15% vs lalu   | |
|  +------------------+ +----------------+ |
|                                          |
|  TREND PENJUALAN & PROFIT                |
|  +------------------------------------+  |
|  | line chart                          | |
|  | omzet = green                       | |
|  | profit = gold                       | |
|  +------------------------------------+  |
|                                          |
|  KAS MASUK vs KAS KELUAR                 |
|  +------------------------------------+  |
|  | bar chart                           | |
|  | masuk = green                       | |
|  | keluar = red                        | |
|  +------------------------------------+  |
|                                          |
|  INSIGHT HARI INI                        |
|  +------------------------------------+  |
|  | Produk terlaris : Indomie          | |
|  | Hari paling ramai: Sabtu           | |
|  | Rata-rata transaksi: Rp 38.000     | |
|  | Tunai 72% | Hutang 28%             | |
|  +------------------------------------+  |
|                                          |
|  TOP PRODUK                              |
|  +------------------------------------+  |
|  | 1. Indomie Goreng       150 terjual | |
|  | 2. Aqua 600ml            85 terjual | |
|  | 3. Rokok Marlboro        42 terjual | |
|  +------------------------------------+  |
|                                          |
|  CATATAN NON-OPERASIONAL                 |
|  +------------------------------------+  |
|  | Ada 3 transaksi di luar operasional | |
|  | Tidak masuk ke KPI utama            | |
|  +------------------------------------+  |
|                                          |
+------------------------------------------+
```

---

## 6. Section Breakdown

### 6.1 Header

```text
+------------------------------------------+
|  Stats                             [..]  |
+------------------------------------------+
```

**Purpose**
- Menandai ini halaman analitik
- Tetap sejalan dengan pola visual CatatCuan

**Behavior**
- Karena `Stats` ada di bottom nav, sisi kanan bisa:
  - menu period detail
  - info icon
  - atau action kecil seperti refresh

**Style**
- Header hijau
- Judul putih
- Tidak perlu tombol close model modal

---

### 6.2 Quick Period Filter

```text
PERIODE
[ 7 Hari ] [ 30 Hari ] [ Bulan Ini ]
[ Custom ]
```

**Purpose**
- Memudahkan ganti horizon data dengan satu tap

**Default Recommendation**
- Default aktif: `7 Hari`

**States**
- Active chip: hijau
- Inactive chip: putih border hijau muda

**Reasoning**
- `Stats` harus cepat, jadi lebih cocok pakai quick chips daripada dropdown tunggal seperti `Laporan`

---

### 6.3 KPI Summary Cards

```text
+------------------+ +----------------+
| Omzet            | | Profit         |
| Rp 2.500.000     | | Rp 875.000     |
| +12% vs lalu     | | +8% vs lalu    |
+------------------+ +----------------+

+------------------+ +----------------+
| Pengeluaran      | | Net Cashflow   |
| Rp 625.000       | | Rp 1.120.000   |
| -4% vs lalu      | | +15% vs lalu   |
+------------------+ +----------------+
```

**Recommended KPIs**
- Omzet
- Profit
- Pengeluaran
- Net Cashflow

**Delta**
Setiap card menampilkan perbandingan dengan periode sebelumnya:
- `+12% vs lalu`
- `-4% vs lalu`

**Color Use**
- Positif = hijau
- Negatif = merah
- Netral = abu

**Design Notes**
- Grid 2x2
- Card putih
- Nilai besar
- Delta kecil tapi jelas

---

### 6.4 Main Trend Chart

```text
TREND PENJUALAN & PROFIT
+--------------------------------------+
| line chart                           |
| omzet = green                        |
| profit = gold                        |
+--------------------------------------+
```

**Purpose**
- Memberi gambaran gerak usaha dari waktu ke waktu

**Chart Type**
- Line chart

**Series**
- Penjualan / omzet
- Profit

**Why This Works**
- User bisa langsung lihat apakah omzet naik tapi profit stagnan
- Sangat membantu dibanding angka statis saja

**Interaction**
- Tap titik data menampilkan tooltip
- Tooltip menampilkan:
  - tanggal
  - omzet
  - profit

---

### 6.5 Cashflow Chart

```text
KAS MASUK vs KAS KELUAR
+--------------------------------------+
| bar chart                            |
| masuk = green                        |
| keluar = red                         |
+--------------------------------------+
```

**Purpose**
- Menjelaskan ritme uang masuk dan keluar
- Membantu user sadar kalau kas keluar terlalu agresif

**Chart Type**
- Bar chart per hari / per minggu tergantung periode aktif

**Series**
- Kas masuk
- Kas keluar

**Recommendation**
- Gunakan warna yang sangat mudah dibedakan
- Jangan mengandalkan warna saja, pakai label dan legenda

---

### 6.6 Insight Card

```text
INSIGHT HARI INI
+--------------------------------------+
| Produk terlaris : Indomie            |
| Hari paling ramai: Sabtu             |
| Rata-rata transaksi: Rp 38.000       |
| Tunai 72% | Hutang 28%               |
+--------------------------------------+
```

**Purpose**
- Mengubah data menjadi insight cepat
- Menjawab pertanyaan owner tanpa harus membaca chart detail

**Recommended Insights**
- Produk terlaris
- Hari paling ramai
- Rata-rata transaksi
- Komposisi pembayaran tunai vs hutang

**Tone**
- Ringkas
- To the point
- Mudah dipahami dalam 5 detik

---

### 6.7 Top Product Section

```text
TOP PRODUK
+--------------------------------------+
| 1. Indomie Goreng       150 terjual  |
| 2. Aqua 600ml            85 terjual  |
| 3. Rokok Marlboro        42 terjual  |
+--------------------------------------+
```

**Purpose**
- Menampilkan produk paling berkontribusi
- Menjadi jembatan antara analytics dan keputusan stok

**Behavior**
- Menampilkan top 3 atau top 5
- Bisa diberi tombol kecil `Lihat Semua` jika nanti berkembang

---

### 6.8 Non-Operational Note Section

```text
CATATAN NON-OPERASIONAL
+--------------------------------------+
| Ada 3 transaksi di luar operasional  |
| Tidak masuk ke KPI utama             |
+--------------------------------------+
```

**Purpose**
- Menjawab kebutuhan agar hutang atau transaksi kecil non-usaha tetap terlihat
- Menjaga KPI utama tetap bersih

**Display Rule**
- Tampil hanya jika data non-operasional ada
- Tidak perlu tampil besar
- Cukup seperti info card / warning card

**Examples**
- Hutang pribadi
- Catatan pengeluaran rumah tangga
- transaksi yang tidak terkait usaha

---

## 7. Chart Detail Recommendation

### Trend Penjualan & Profit
- Chart: `Line chart`
- X-axis:
  - harian untuk `7 Hari` dan `30 Hari`
  - mingguan / tanggal kelompok untuk `Bulan Ini`
- Y-axis:
  - nilai rupiah
- Series:
  - omzet
  - profit

### Kas Masuk vs Kas Keluar
- Chart: `Bar chart`
- X-axis:
  - hari
- Y-axis:
  - nilai rupiah
- Series:
  - kas masuk
  - kas keluar

### Why No Pie Chart For Main View
- Pie chart kurang kuat untuk membaca trend
- `Stats` harus membantu baca perubahan waktu, bukan cuma komposisi

---

## 8. States

### 8.1 Loading State

```text
+------------------------------------------+
|  Stats                             [..]  |
+------------------------------------------+
|  [ CHIP SKELETON ] [ CHIP SKELETON ]     |
|                                          |
|  +------------------+ +----------------+ |
|  |    SKELETON      | |   SKELETON     | |
|  +------------------+ +----------------+ |
|                                          |
|  +------------------+ +----------------+ |
|  |    SKELETON      | |   SKELETON     | |
|  +------------------+ +----------------+ |
|                                          |
|  [ CHART SKELETON ]                      |
|  [ CHART SKELETON ]                      |
|  [ INSIGHT SKELETON ]                    |
+------------------------------------------+
```

**Recommendation**
- Skeleton lebih cocok daripada spinner panjang
- Jaga agar area chart tetap punya placeholder

---

### 8.2 Empty State

```text
+------------------------------------------+
|  Stats                             [..]  |
+------------------------------------------+
|  [ 7 Hari ] [ 30 Hari ] [ Bulan Ini ]    |
|                                          |
|            [ icon analytics ]            |
|          Belum ada statistik             |
|  Mulai catat transaksi untuk melihat     |
|  performa usaha secara visual.           |
+------------------------------------------+
```

**When Used**
- Belum ada penjualan dan pengeluaran yang cukup untuk dihitung

---

### 8.3 Partial Empty State

```text
TOP PRODUK
+--------------------------------------+
| Belum ada produk terjual             |
+--------------------------------------+
```

```text
CATATAN NON-OPERASIONAL
+--------------------------------------+
| Tidak ada transaksi non-operasional  |
+--------------------------------------+
```

---

## 9. Components Breakdown

| Component | Description |
|----------|-------------|
| Header | Title `Stats` + helper action |
| Period Chips | Quick period filter |
| KPI Cards | 4 kartu ringkasan utama |
| Trend Chart | Grafik omzet dan profit |
| Cashflow Chart | Grafik kas masuk vs kas keluar |
| Insight Card | Ringkasan insight cepat |
| Top Product List | Produk performa terbaik |
| Non-Operational Card | Informasi data di luar usaha |

---

## 10. Data Mapping Recommendation

### KPI
- `Omzet` = sum `PENJUALAN.total_amount`
- `Profit` = sum `PENJUALAN.profit`
- `Pengeluaran` = sum `PENGELUARAN.amount`
- `Net Cashflow` = total kas masuk - total kas keluar dari `BUKU_KAS`

### Trend Penjualan & Profit
- Source:
  - `PENJUALAN`
- Group by:
  - hari / bucket periode

### Cashflow
- Source:
  - `BUKU_KAS`
- Split:
  - `tipe = masuk`
  - `tipe = keluar`

### Insight
- `Produk terlaris` = top item dari `PENJUALAN_ITEM`
- `Hari paling ramai` = hari dengan jumlah transaksi tertinggi dari `PENJUALAN`
- `Rata-rata transaksi` = total omzet / jumlah transaksi
- `Tunai vs Hutang` = split `payment_method` dari `PENJUALAN`

### Non-Operational Data
Jika nanti tersedia penanda `operasional` vs `non-operasional`, maka:
- KPI utama hanya ambil `operasional = true`
- Section catatan mengambil `operasional = false`

---

## 11. Interaction Flow

1. User buka tab `Stats`
2. Halaman load dengan periode default `7 Hari`
3. User scan KPI cards
4. User baca trend penjualan dan cashflow
5. User lihat insight cepat
6. User ganti periode jika ingin analisis lebih panjang
7. User lanjut ke `Laporan` jika butuh export formal

---

## 12. UX Rules For This Page

- Harus lebih visual daripada `Laporan`
- KPI utama hanya untuk operasional usaha
- Non-operasional tidak boleh merusak pembacaan bisnis inti
- Hindari terlalu banyak chart dalam satu layar
- Minimal 1 chart trend dan 1 chart cashflow sudah cukup untuk V1
- Insight harus bisa dibaca tanpa membuka chart detail
- Delta perbandingan harus singkat dan jelas

---

## 13. Future Extension

- Tambah tab insight mingguan / bulanan
- Tambah kategori pengeluaran terbesar
- Tambah pelanggan paling sering belanja
- Tambah stok menipis vs produk terlaris
- Tambah toggle `Operasional saja`
- Tambah deep link ke detail transaksi per chart point

---

## 14. Implementation Notes

### Recommended V1 Scope
- Quick period chips
- 4 KPI cards
- 1 line chart omzet + profit
- 1 bar chart kas masuk + kas keluar
- 1 insight card
- 1 top product list

### Explicit Non-Scope For V1
- Export Excel/PDF
- filter report type
- analytics yang terlalu dalam
- dashboard dengan 5+ chart

Alasan: `Stats` harus tetap ringan dan cepat dipahami.

---

## 15. Final Direction

Halaman `Stats` CatatCuan harus terasa seperti:
- cepat
- visual
- tajam
- membantu owner membaca kesehatan usaha

Bukan halaman dokumen, dan bukan juga halaman keuangan formal.  
`Stats` adalah tempat user melihat apakah usaha sedang membaik, stagnan, atau perlu perhatian.
