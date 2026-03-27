# Gemini CLI Prompt - Implementasi Halaman Settings CatatCuan

Gunakan prompt di bawah ini untuk Gemini CLI.

```text
Kamu adalah senior Flutter engineer + product-minded mobile UI engineer yang bertugas mengimplementasikan halaman `Settings` untuk project CatatCuan.

Kerjakan implementasi nyata di codebase ini, bukan demo, bukan pseudo-code, dan bukan dummy data.

Sebelum mulai, WAJIB baca file-file berikut dan jadikan itu sumber konteks utama:

1. Wireframe utama settings:
- AI-Agent/Output/Design/CatatCuan/wireframes/settings-page-wireframe.md

2. Skill / aturan UI-UX:
- .agent/ui-ux-pro-max/SKILL.md

3. Database schema:
- catatcuan-admin/catatcuan_schema.sql

4. File referensi design system / pola existing mobile:
- catatcuan-mobile/lib/core/theme/app_theme.dart
- catatcuan-mobile/lib/core/router/app_router.dart
- catatcuan-mobile/lib/features/home/presentation/pages/home_page.dart
- catatcuan-mobile/lib/features/buku_kas/buku_kas_page.dart
- catatcuan-mobile/lib/features/laporan/presentation/pages/laporan_page.dart
- catatcuan-mobile/lib/features/stats/presentation/pages/stats_page.dart
- catatcuan-mobile/lib/features/settings/settings_page.dart

5. File referensi data / session / profile:
- catatcuan-mobile/lib/core/services/session_service.dart
- catatcuan-mobile/lib/core/services/data_cache_service.dart
- catatcuan-mobile/lib/features/onboarding/presentation/pages/onboarding_page.dart
- catatcuan-mobile/lib/features/onboarding/presentation/widgets/onboarding_profile.dart

Tujuan utama:
- implement halaman `/setting` sesuai wireframe settings
- UI harus konsisten dengan halaman CatatCuan yang lain
- UX harus matang dan mudah dipahami user usia 45 tahun ke atas
- halaman harus terasa rapi, aman, dan mudah discan
- upgrade `SettingsPage` yang sekarang masih minimal menjadi page pengaturan yang benar-benar usable

Konteks produk:
- CatatCuan saat ini difokuskan untuk owner warung
- `Settings` bukan halaman transaksi, bukan analytics, dan bukan tempat semua menu dilempar tanpa struktur
- `Settings` adalah pusat utilitas akun, warung, preferensi sederhana, bantuan, dan aksi sensitif seperti logout
- user utama perlu cepat mengerti fungsi tiap item tanpa bingung

Aturan UX untuk user 45+:
- hierarchy harus sangat jelas
- bahasa harus sederhana dan familiar
- touch target besar dan nyaman
- subtitle item harus membantu menjelaskan fungsi menu
- jangan terlalu banyak pilihan dalam satu area
- aksi sensitif harus dipisahkan jelas
- kontras tinggi, jangan abu-abu terlalu pucat
- hindari interaksi tersembunyi
- loading / fallback state harus membantu

Aturan desain dan konsistensi visual:
- jangan buat desain yang berbeda sendiri dari app yang sudah ada
- ikuti gaya visual CatatCuan yang sekarang
- pertahankan nuansa:
  - background page abu muda `#F8F9FA`
  - card putih
  - border halus / shadow ringan
  - warna utama hijau CatatCuan `#13B158`
  - warna destruktif merah hanya dipakai untuk area sensitif
- typography tetap `Poppins`
- gunakan header hijau yang konsisten dengan page existing
- spacing harus lega dan rapi
- gunakan komponen yang terasa native Flutter mobile, bukan web-ish
- animasi secukupnya, jangan ramai

Implementasi yang diharapkan:

1. Upgrade halaman settings yang ada sekarang:
- file target utama: `catatcuan-mobile/lib/features/settings/settings_page.dart`
- route `/setting` sudah ada, jadi fokusnya mengganti isi page agar sesuai wireframe

2. Implement struktur halaman mengikuti wireframe:
- Header `Pengaturan`
- Profile summary card
- Section `Akun`
- Section `Preferensi`
- Section `Data & Warung`
- Section `Bantuan & Info`
- Section `Danger Zone`

3. Profile summary card minimal menampilkan:
- nama pemilik / nama user
- nama warung
- nomor telepon jika tersedia
- tombol `Edit Profil`

4. Data untuk profile summary harus ambil dari source nyata yang sudah ada di codebase.
Prioritas data source:
- session aktif
- data user / warung dari Supabase
- cache lokal bila memang sudah ada dan relevan

Jika ada perbedaan struktur antara schema SQL dan codebase aktif:
- prioritaskan codebase Flutter yang aktif
- adaptasikan dengan wireframe tanpa merusak flow yang sudah ada

5. Section `Akun` minimal support:
- `Profil Saya`
- `Data Warung`
- `Ubah Password`

6. Section `Preferensi` minimal support:
- `Periode Default`
- `Notifikasi`
- `Bahasa`

Jika beberapa preferensi belum punya backend/source yang kompleks:
- boleh simpan lokal dulu dengan pendekatan sederhana yang rapi
- jangan pakai dummy visual tanpa state nyata
- minimal item harus punya arah interaksi yang jelas: detail page, bottom sheet, dialog, toggle, atau placeholder yang jujur dan rapi

7. Section `Data & Warung` minimal support:
- `Kategori Produk`
- `Kategori Pengeluaran`
- `Satuan Produk`
- `Saldo Awal`

Kalau belum semua punya halaman detail siap pakai:
- siapkan UX yang jelas dan extensible
- jangan bohongi user dengan tombol mati
- boleh arahkan ke placeholder ringan yang menjelaskan fitur akan hadir, atau route existing jika memang sudah ada

8. Section `Bantuan & Info` minimal support:
- `Pusat Bantuan`
- `Tentang Aplikasi`
- `Kebijakan Privasi`

Untuk V1:
- tidak perlu integrasi bantuan kompleks
- tapi item harus punya interaksi nyata yang masuk akal, misalnya bottom sheet, dialog, atau halaman sederhana

9. Section `Danger Zone`:
- `Keluar Aplikasi`
- harus tampil terpisah jelas dari item biasa
- wajib ada dialog konfirmasi sebelum logout

10. Konfirmasi logout:
- gunakan dialog yang jelas dan mudah dipahami
- tombol `Batal` dan `Keluar` harus jelas bedanya
- jika logout berhasil, arahkan ke welcome / login sesuai flow app saat ini

11. Layout item settings:
- gunakan pola item yang informatif:
  - icon
  - title
  - subtitle pendek
  - chevron
- satu item harus mudah dipahami tanpa dibuka dulu

12. Arsitektur kode:
- jangan taruh semua logic besar langsung di `build`
- buat helper widget / section builder jika perlu
- jika perlu service tambahan untuk profile / preference, buat dengan rapi
- jangan refactor besar yang tidak perlu
- jaga page tetap fokus ke UI + orchestration

13. Loading / empty / fallback / error states:
- loading state untuk summary profile
- fallback state jika data warung belum lengkap
- error handling yang jelas untuk logout atau load data profile

14. Responsiveness dan ergonomi:
- harus enak di mobile portrait
- tidak ada horizontal overflow
- aman untuk layar kecil
- list item tetap nyaman disentuh
- content tidak terasa padat

15. Accessibility dan readability:
- ukuran font nyaman
- subtitle tidak terlalu kecil
- jangan andalkan warna saja untuk aksi sensitif
- touch target minimal nyaman untuk jari
- dialog konfirmasi harus jelas

16. Konsistensi istilah:
- gunakan istilah yang konsisten dengan app:
  - Pengaturan
  - Profil Saya
  - Data Warung
  - Ubah Password
  - Kategori Produk
  - Kategori Pengeluaran
  - Satuan Produk
  - Saldo Awal
  - Pusat Bantuan
  - Tentang Aplikasi
  - Kebijakan Privasi
  - Keluar Aplikasi
- tetap fokus ke konteks warung, bukan UMKM umum

17. Jangan gunakan dummy data.
- jangan hardcode nama palsu sebagai data final
- jangan bikin profile summary fake
- data nyata harus diambil dari session / Supabase / source aktif yang ada
- untuk fitur yang belum punya data source final, tampilkan interaksi yang jujur dan ringan

18. Jangan merusak halaman lain.
- jaga perubahan tetap fokus
- preserve style existing
- jangan refactor besar yang tidak diperlukan

Recommended V1 scope:
- Header
- Profile summary
- Akun section
- Preferensi section sederhana
- Data & Warung section dasar
- Bantuan & Info section sederhana
- Logout confirmation yang rapi

Explicit non-scope untuk langkah ini:
- backup/sync kompleks
- offline-first setting
- device management
- dark mode penuh
- konfigurasi printer yang kompleks

Deliverables yang saya harapkan:
- implementasi page settings yang nyata di Flutter
- route `/setting` tetap aktif dengan UI baru
- profile summary dengan data nyata
- struktur section sesuai wireframe
- logout confirmation yang rapi
- interaksi item settings jelas dan tidak membingungkan
- kode rapi dan konsisten dengan project

Saat selesai, berikan ringkasan:
- file yang diubah
- keputusan desain utama
- keputusan data/profile source utama
- interaksi item mana yang fully implemented
- item mana yang masih placeholder terarah kalau ada

Penting:
- jangan pakai data dummy
- jangan bikin desain melenceng dari CatatCuan
- prioritaskan UX yang matang untuk user 45+
- tetap ikuti wireframe settings sebagai acuan utama
- jangan over-engineer fitur setting yang belum dibutuhkan sekarang
```

## Catatan Pakai

Kalau kamu mau hasil Gemini lebih presisi lagi, kirim prompt di atas bersamaan dengan instruksi singkat ini:

```text
Mulai dengan membaca semua file referensi yang saya sebut. Setelah itu implement langsung di codebase, bukan hanya memberi rencana. Jika ada perbedaan antara schema SQL dan kondisi code Flutter saat ini, prioritaskan code yang aktif lalu adaptasikan dengan wireframe settings. Fokus ke UX yang sederhana, jelas, dan cocok untuk owner warung.
```
