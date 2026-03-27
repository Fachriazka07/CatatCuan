# Gemini CLI Prompt - Implementasi Halaman Stats CatatCuan

Gunakan prompt di bawah ini untuk Gemini CLI.

```text
Kamu adalah senior Flutter engineer + product-minded mobile analytics UI engineer yang bertugas mengimplementasikan halaman `Stats` untuk project CatatCuan.

Kerjakan implementasi nyata di codebase ini, bukan demo, bukan pseudo-code, dan bukan dummy data.

Sebelum mulai, WAJIB baca file-file berikut dan jadikan itu sumber konteks utama:

1. Wireframe utama stats:
- AI-Agent/Output/Design/CatatCuan/wireframes/stats-page-wireframe.md

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
- catatcuan-mobile/lib/features/laporan/presentation/pages/laporan_page.dart
- catatcuan-mobile/lib/features/settings/settings_page.dart

5. File referensi data / service / transaksi:
- catatcuan-mobile/lib/core/services/laporan_service.dart
- catatcuan-mobile/lib/core/services/data_cache_service.dart
- catatcuan-mobile/lib/core/services/hutang_service.dart
- catatcuan-mobile/lib/features/penjualan/checkout_page.dart
- catatcuan-mobile/lib/features/pengeluaran/insert_pengeluaran.dart

Tujuan utama:
- implement halaman `/stats` sesuai wireframe stats
- UI harus konsisten dengan halaman CatatCuan yang lain
- UX harus matang dan mudah dipahami user usia 45 tahun ke atas
- pakai data nyata dari Supabase, jangan gunakan dummy data
- `Stats` harus terasa cepat, visual, dan mudah dibaca dalam sekali scroll

Konteks produk:
- CatatCuan saat ini difokuskan untuk owner warung
- `Stats` adalah halaman analitik cepat, bukan halaman export / dokumen
- `Laporan` sudah diposisikan sebagai rekap formal, jadi `Stats` harus berbeda secara fungsi dan nuansa
- `Stats` ada di bottom navbar, jadi harus cepat dipahami, ringan, dan tidak berantakan

Aturan UX untuk user 45+:
- hierarchy harus sangat jelas
- angka utama harus besar dan mudah dibaca
- kontras tinggi, jangan abu-abu terlalu pucat
- touch target besar dan nyaman
- bahasa sederhana dan familiar
- minim clutter
- hindari interaksi tersembunyi
- chart harus mudah dibaca, tidak terlalu ramai
- insight harus bisa dipahami tanpa perlu membaca chart terlalu detail
- loading, empty, dan error state harus jelas

Aturan desain dan konsistensi visual:
- jangan buat desain yang berbeda sendiri dari app yang sudah ada
- ikuti gaya visual CatatCuan yang sekarang
- pertahankan nuansa:
  - background page abu muda `#F8F9FA`
  - card putih
  - border hijau muda `#D1EDD8`
  - warna utama hijau CatatCuan `#13B158`
  - aksen merah `#DC2626` untuk penurunan / kas keluar
  - aksen emas `#EAA220` untuk highlight insight / series kedua
- typography tetap sejalan dengan mobile app sekarang
- gunakan header hijau yang konsisten dengan halaman lain
- jaga spacing lega dan bersih
- gunakan komponen yang terasa native Flutter mobile, bukan web-ish
- animasi secukupnya, jangan ramai

Aturan chart:
- fokus pada readability, bukan dekorasi
- gunakan warna dan label, jangan mengandalkan warna saja
- hindari chart yang terlalu padat
- cukup 2 chart utama untuk V1:
  - line chart trend penjualan dan profit
  - bar chart kas masuk vs kas keluar
- tooltip harus jelas dan sederhana
- axis/legend harus mudah dipahami user awam
- jika perlu menambah dependency chart, lakukan dengan rapi dan pilih library Flutter yang stabil
- chart boleh dan sebaiknya punya animasi masuk / update yang halus
- animasi chart harus terasa hidup tapi tetap ringan
- hindari animasi berlebihan, bouncing yang ramai, atau transisi lambat
- gunakan durasi singkat sekitar 200-350ms
- animasi harus membantu pemahaman perubahan data, bukan sekadar dekorasi
- pastikan performa tetap halus di device kelas menengah
- warna chart harus tetap selaras dengan CatatCuan:
  - series utama pakai hijau primary CatatCuan atau turunannya
  - series sekunder pakai aksen emas untuk pembanding positif
  - series kas keluar pakai merah yang tetap harmonis dengan palette app
- jangan gunakan warna random yang keluar dari identitas visual app

Penting:
Wireframe stats saat ini menyebut quick period seperti `7 Hari`, `30 Hari`, `Bulan Ini`, `Custom`.
Tetapi untuk implementasi ini, OVERRIDE bagian itu dan gunakan filter periode berikut:
- Harian
- Mingguan
- Bulanan
- Triwulanan

Artinya:
- jangan implement 7 hari / 30 hari sebagai chip utama
- chip utama yang tampil harus `Harian`, `Mingguan`, `Bulanan`, `Triwulanan`
- sesuaikan semua grouping data, chart bucket, delta comparison, dan label berdasarkan 4 periode itu

Definisi periode yang diharapkan:
- `Harian`: fokus hari ini, dengan pembanding hari sebelumnya
- `Mingguan`: periode minggu berjalan, dengan pembanding minggu sebelumnya
- `Bulanan`: periode bulan berjalan, dengan pembanding bulan sebelumnya
- `Triwulanan`: periode 3 bulan berjalan, dengan pembanding 3 bulan sebelumnya

Implementasi yang diharapkan:

1. Buat halaman stats yang benar-benar menggantikan placeholder route `/stats`

2. Implement struktur halaman mengikuti wireframe stats:
- Header
- Quick period filter
- 4 KPI summary cards
- Trend chart penjualan & profit
- Cashflow chart
- Insight card
- Top product section
- Non-operational note section jika memang datanya tersedia

3. Data harus diambil dari database nyata Supabase berdasarkan schema dan flow transaksi yang sudah ada.

Gunakan data mapping berikut:
- `Omzet` = sum `PENJUALAN.total_amount`
- `Profit` = sum `PENJUALAN.profit`
- `Pengeluaran` = sum `PENGELUARAN.amount`
- `Net Cashflow` = total kas masuk - total kas keluar dari `BUKU_KAS`
- `Kas Masuk` = sum `BUKU_KAS.amount` where `tipe = masuk`
- `Kas Keluar` = sum `BUKU_KAS.amount` where `tipe = keluar`
- `Jumlah Transaksi` = count `PENJUALAN`
- `Produk Terlaris` = top item dari `PENJUALAN_ITEM`
- `Hari paling ramai` = bucket/hari dengan jumlah transaksi tertinggi
- `Rata-rata transaksi` = total omzet / jumlah transaksi
- `Tunai vs Hutang` = split `PENJUALAN.payment_method`

4. Delta comparison wajib ada pada KPI utama.
Setiap KPI card harus menampilkan perbandingan dengan periode sebelumnya:
- Harian vs hari sebelumnya
- Mingguan vs minggu sebelumnya
- Bulanan vs bulan sebelumnya
- Triwulanan vs 3 bulan sebelumnya

5. Grouping data wajib menyesuaikan periode:
- `Harian`: gunakan bucket jam atau sub-ringkasan hari ini bila cocok, tapi halaman tetap harus sederhana
- `Mingguan`: group per hari
- `Bulanan`: group per minggu atau per tanggal secara ringkas
- `Triwulanan`: group per bulan

6. Insight section minimal menampilkan:
- Produk terlaris
- Hari/periode paling ramai
- Rata-rata transaksi
- Komposisi pembayaran tunai vs hutang

7. Top product section:
- tampilkan minimal top 3
- gunakan data real
- jangan hardcode produk

8. Non-operational note:
- kalau codebase / schema saat ini belum punya penanda non-operasional yang reliable, tampilkan section ini hanya jika benar-benar bisa dihitung
- jangan memaksakan fake implementation
- jika belum ada data source yang layak, boleh buat section kondisional yang tidak tampil

9. Arsitektur kode:
- jangan taruh seluruh query dan logic besar langsung di page
- buat service stats terpisah, misalnya:
  - `catatcuan-mobile/lib/core/services/stats_service.dart`
- jaga page tetap fokus ke UI + orchestration
- boleh reuse helper dari `laporan_service.dart` bila relevan, tapi jangan campur semua logic ke satu file besar jika jadi tidak rapi

10. Route integration:
- ganti placeholder route `/stats` di router menjadi page nyata

11. Loading / empty / error states:
- loading state sebaiknya pakai skeleton / placeholder ringan
- empty state harus membantu
- error state dengan pesan jelas dan action retry bila perlu

12. Responsiveness dan ergonomi:
- harus enak di mobile portrait
- tidak ada horizontal overflow
- aman untuk layar kecil
- chart dan card tetap terbaca
- hindari text terlalu kecil
- animasi chart tidak boleh membuat scroll terasa berat atau janky

13. Accessibility dan readability:
- gunakan ukuran font yang nyaman
- jangan mengandalkan warna saja untuk delta/state
- selected state pada filter periode harus jelas
- chart legend dan tooltip harus mudah dipahami user awam
- jaga touch target minimal nyaman untuk jari

14. Konsistensi istilah:
- gunakan istilah yang konsisten dengan app:
  - Stats
  - Omzet
  - Profit
  - Pengeluaran
  - Net Cashflow
  - Kas Masuk
  - Kas Keluar
  - Produk Terlaris
  - Hutang
  - Buku Kas
- tetap fokus ke konteks warung

15. Jangan gunakan dummy data.
- jangan hardcode angka palsu
- jangan buat fake chart series
- semua harus connect ke Supabase nyata
- kalau schema SQL berbeda sedikit dengan implementasi mobile terbaru, prioritaskan kondisi codebase berjalan saat ini, lalu sesuaikan dengan wireframe

16. Jangan merusak halaman lain.
- jaga perubahan tetap fokus
- preserve style existing
- jangan refactor besar yang tidak diperlukan

Deliverables yang saya harapkan:
- implementasi page stats yang nyata di Flutter
- service stats untuk query data
- route `/stats` aktif
- UI sesuai wireframe stats
- filter periode `Harian`, `Mingguan`, `Bulanan`, `Triwulanan`
- data real dari Supabase
- chart terbaca dan konsisten dengan CatatCuan
- chart punya animasi ringan yang halus dan tidak membebani performa
- kode rapi dan konsisten dengan project

Saat selesai, berikan ringkasan:
- file yang diubah
- keputusan desain utama
- keputusan query/data utama
- keputusan grouping periode
- dependency baru jika ada
- hal yang belum dikerjakan kalau ada

Penting:
- jangan pakai data dummy
- jangan bikin desain melenceng dari CatatCuan
- prioritaskan UX yang matang untuk user 45+
- tetap ikuti wireframe stats sebagai acuan utama
- override quick filter menjadi `Harian`, `Mingguan`, `Bulanan`, `Triwulanan`
```

## Catatan Pakai

Kalau kamu mau hasil Gemini lebih presisi lagi, kirim prompt di atas bersamaan dengan instruksi singkat ini:

```text
Mulai dengan membaca semua file referensi yang saya sebut. Setelah itu implement langsung di codebase, bukan hanya memberi rencana. Jika ada perbedaan antara wireframe stats dan kebutuhan periode terbaru saya, prioritaskan periode `Harian`, `Mingguan`, `Bulanan`, dan `Triwulanan`. Jika ada perbedaan antara schema SQL dan code Flutter aktif, prioritaskan code yang aktif lalu adaptasikan dengan wireframe.
```
