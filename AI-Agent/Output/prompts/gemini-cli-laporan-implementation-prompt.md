# Gemini CLI Prompt - Implementasi Halaman Laporan CatatCuan

Gunakan prompt di bawah ini untuk Gemini CLI.

```text
Kamu adalah senior Flutter engineer + product-minded mobile UI engineer yang bertugas mengimplementasikan halaman `Laporan` untuk project CatatCuan.

Kerjakan implementasi nyata di codebase ini, bukan demo, bukan pseudo-code, dan bukan dummy data.

Sebelum mulai, WAJIB baca file-file berikut dan jadikan itu sumber konteks utama:

1. Wireframe utama laporan:
- AI-Agent/Output/Design/CatatCuan/wireframes/laporan-page-wireframe.md

2. Skill / aturan UI-UX:
- .agent/ui-ux-pro-max/SKILL.md

3. Database schema:
- catatcuan-admin/catatcuan_schema.sql

4. File referensi design system / pola existing mobile:
- catatcuan-mobile/lib/core/theme/app_theme.dart
- catatcuan-mobile/lib/core/router/app_router.dart
- catatcuan-mobile/lib/features/home/presentation/pages/home_page.dart
- catatcuan-mobile/lib/features/buku_kas/buku_kas_page.dart
- catatcuan-mobile/lib/features/pengeluaran/pengeluaran_list.dart
- catatcuan-mobile/lib/features/pelanggan/customer_list.dart
- catatcuan-mobile/lib/features/produk/product_list.dart
- catatcuan-mobile/lib/features/settings/settings_page.dart

5. File referensi data / service / transaksi:
- catatcuan-mobile/lib/core/services/data_cache_service.dart
- catatcuan-mobile/lib/core/services/hutang_service.dart
- catatcuan-mobile/lib/features/penjualan/checkout_page.dart
- catatcuan-mobile/lib/features/pengeluaran/insert_pengeluaran.dart

Tujuan utama:
- implement halaman `/laporan` sesuai wireframe
- UI harus konsisten dengan halaman CatatCuan yang lain
- UX harus matang dan mudah dipahami user usia 45 tahun ke atas
- pakai data nyata dari Supabase, jangan gunakan dummy data
- gunakan istilah bisnis yang konsisten dengan app

Konteks produk:
- `Laporan` adalah halaman rekap dan export, bukan analytics dashboard
- `Stats` sudah diposisikan untuk trend/chart, jadi `Laporan` jangan dibuat terlalu analitik
- `Laporan` harus terasa rapi, formal ringan, mudah dipindai, dan siap jadi dokumen

Aturan UX untuk user 45+:
- hierarchy harus sangat jelas
- angka utama harus besar dan mudah dibaca
- kontras tinggi, jangan abu-abu terlalu pucat
- hindari interaksi tersembunyi
- touch target besar dan nyaman
- bahasa sederhana dan familiar
- minim clutter
- hindari istilah teknis yang tidak perlu
- section harus jelas dan tidak membingungkan
- empty/loading states harus membantu, bukan cuma spinner

Aturan desain dan konsistensi visual:
- jangan buat desain yang berbeda sendiri dari app yang sudah ada
- ikuti gaya visual CatatCuan yang sekarang
- pertahankan nuansa:
  - background page abu muda `#F8F9FA`
  - card putih
  - border hijau muda `#D1EDD8`
  - warna utama hijau CatatCuan `#13B158`
  - aksen emas `#EAA220`
- gunakan pola header yang konsisten dengan page existing
- jaga spacing lega dan bersih
- gunakan komponen yang terasa native Flutter mobile, bukan web-ish
- jangan gunakan chart di halaman laporan
- animasi secukupnya, jangan ramai

Implementasi yang diharapkan:

1. Buat halaman laporan yang benar-benar menggantikan placeholder route `/laporan`

2. Implement struktur halaman mengikuti wireframe:
- Header
- Periode laporan
- Main summary card `Laba Bersih`
- 4 summary cards
- Jenis laporan
- Produk terlaris
- Export action

3. Data harus diambil dari database nyata Supabase berdasarkan schema dan flow transaksi yang sudah ada.

Gunakan data mapping berikut:
- `Penjualan` = sum `PENJUALAN.total_amount`
- `Profit Penjualan` = sum `PENJUALAN.profit`
- `Pengeluaran` = sum `PENGELUARAN.amount`
- `Laba Bersih` = sum `PENJUALAN.profit` - sum `PENGELUARAN.amount`
- `Uang Kas Masuk` = sum `BUKU_KAS.amount` where `tipe = masuk`
- `Uang Kas Keluar` = sum `BUKU_KAS.amount` where `tipe = keluar`
- `Produk Terlaris` dari `PENJUALAN_ITEM` grouped by produk/nama_produk ordered by total quantity desc
- `Laporan Hutang/Piutang` pakai `HUTANG` dan `PEMBAYARAN_HUTANG`

4. Period selector wajib support:
- Hari ini
- Minggu ini
- Bulan ini
- Custom

5. Report type list minimal support:
- Ringkasan Keuangan
- Laporan Penjualan
- Laporan Pengeluaran
- Laporan Buku Kas
- Laporan Hutang/Piutang

6. Export section:
- untuk sekarang siapkan UX, state, dan struktur tombol `Export Excel` dan `Export PDF`
- kalau implementasi export penuh terlalu besar untuk satu langkah, minimal siapkan arsitektur dan callback nyata, bukan tombol mati tanpa arah
- kalau ada dependency tambahan yang memang perlu, jelaskan dan tambahkan dengan rapi

7. Arsitektur kode:
- jangan taruh seluruh query dan logic besar langsung di page
- buat service terpisah untuk laporan, misalnya:
  - `catatcuan-mobile/lib/core/services/laporan_service.dart`
- jaga page tetap fokus ke UI + orchestration
- gunakan pola yang masih nyambung dengan codebase sekarang

8. Route integration:
- ganti placeholder route `/laporan` di router menjadi page nyata

9. Loading / empty / error states:
- loading state yang layak
- empty state yang membantu
- error state dengan pesan jelas

10. Responsiveness dan ergonomi:
- harus enak di mobile portrait
- tidak ada horizontal overflow
- aman untuk layar kecil
- teks dan angka harus tetap nyaman dibaca

11. Accessibility dan readability:
- gunakan ukuran font yang nyaman
- jangan mengandalkan warna saja untuk state penting
- selected state `Jenis Laporan` harus jelas
- tombol export harus jelas disabled/enabled state-nya

12. Konsistensi istilah:
- gunakan istilah yang konsisten dengan app:
  - Penjualan
  - Pengeluaran
  - Profit Penjualan
  - Laba Bersih
  - Buku Kas
  - Hutang/Piutang
- jangan ganti istilah seenaknya

13. Jangan gunakan dummy data.
- jangan hardcode angka palsu
- jangan buat fake list produk terlaris
- semua harus connect ke Supabase nyata
- kalau schema SQL berbeda sedikit dengan implementasi mobile terbaru, prioritaskan kondisi codebase berjalan saat ini, lalu sesuaikan dengan wireframe

14. Jangan merusak halaman lain.
- jaga perubahan tetap fokus
- preserve style existing
- jangan refactor besar yang tidak diperlukan

Deliverables yang saya harapkan:
- implementasi page laporan yang nyata di Flutter
- service laporan untuk query data
- route `/laporan` aktif
- UI sesuai wireframe
- data real dari Supabase
- export section siap dikembangkan
- kode rapi dan konsisten dengan project

Saat selesai, berikan ringkasan:
- file yang diubah
- keputusan desain utama
- keputusan query/data utama
- hal yang belum dikerjakan kalau ada

Penting:
- jangan pakai data dummy
- jangan bikin desain melenceng dari CatatCuan
- prioritaskan UX yang matang untuk user 45+
- tetap ikuti wireframe laporan sebagai acuan utama
```

## Catatan Pakai

Kalau kamu mau hasil Gemini lebih presisi lagi, kirim prompt di atas bersamaan dengan instruksi singkat ini:

```text
Mulai dengan membaca semua file referensi yang saya sebut. Setelah itu implement langsung di codebase, bukan hanya memberi rencana. Jika ada perbedaan antara schema SQL dan kondisi code Flutter saat ini, prioritaskan code yang aktif lalu adaptasikan dengan wireframe.
```
