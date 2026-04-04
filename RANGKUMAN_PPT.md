# Rangkuman Untuk PPT

Dokumen ini adalah versi ringkas dari seluruh proses pengerjaan, difokuskan untuk kebutuhan presentasi.

## 1. Latar Belakang

CatatCuan adalah aplikasi pencatatan dan operasional warung yang terdiri dari:

- aplikasi mobile untuk pengguna warung
- admin panel/backend untuk pengelolaan data, notifikasi, dan layanan pendukung

Tujuan pengembangan selama proses ini adalah menyelesaikan sistem agar siap dipakai, diuji, dan dipresentasikan.

## 2. Masalah Utama

Beberapa masalah utama yang ditemukan selama pengembangan:

### 2.1 Backend dan Deploy

- backend mobile masih bergantung pada lokal
- admin panel belum sepenuhnya siap production
- notifikasi dan forgot password belum selesai terhubung penuh
- perlu deploy ke server agar mobile bisa berjalan tanpa backend lokal

### 2.2 Mobile App

- ada error type pada beberapa halaman Flutter
- onboarding sempat terasa stuck di proses penyimpanan
- beberapa UI belum rapi atau tidak konsisten
- ada masalah overflow di notifikasi
- beberapa top bar tabrakan dengan status bar

### 2.3 Notifikasi dan Reminder

- perlu sistem notifikasi push
- perlu test manual notifikasi
- perlu reminder otomatis pagi dan malam

### 2.4 Printer Bluetooth

- tombol cetak struk awalnya belum berfungsi
- printer Bluetooth tidak langsung terdeteksi
- ada masalah plugin printer dan permission
- hasil struk sempat terpotong di bagian bawah

### 2.5 Kesiapan Aplikasi

- aplikasi belum sepenuhnya siap untuk diberikan ke client
- analyzer Flutter masih menunjukkan warning/info

## 3. Tujuan Pengerjaan

Tujuan utama dari seluruh proses ini adalah:

1. menyelesaikan backend admin dan deploy ke production
2. menghubungkan mobile ke backend production
3. menambahkan fitur notifikasi dan forgot password
4. memperbaiki error Flutter yang menghambat jalannya aplikasi
5. menambahkan fitur printer Bluetooth untuk cetak struk
6. merapikan UI agar lebih konsisten dan layak dipresentasikan
7. menyiapkan aplikasi untuk testing client dan demo

## 4. Solusi yang Dilakukan

### 4.1 Backend Admin

Yang diselesaikan:

- mobile backend API
- push notification service
- password reset dengan Twilio Verify
- route internal notifikasi
- cron reminder pagi dan malam
- panel test notifikasi di admin

Hasil:

- backend admin berhasil disiapkan dan dideploy ke Vercel
- mobile tidak lagi bergantung pada backend lokal

### 4.2 Integrasi Production

Yang dilakukan:

- konfigurasi environment variables di Vercel
- penyambungan mobile ke URL backend production
- penyesuaian `DATABASE_URL`, secret, dan Firebase config

Hasil:

- backend production aktif di domain Vercel
- mobile bisa diarahkan ke backend production

### 4.3 Perbaikan Mobile App

Yang diperbaiki:

- error type pada buku kas, receipt, checkout, dan stats
- flow onboarding agar tidak terlalu bergantung pada preload lama
- beberapa UI yang overflow atau tabrakan
- top bar halaman tertentu agar konsisten

Hasil:

- error merah compile sudah hilang
- aplikasi menjadi lebih stabil untuk demo dan testing

### 4.4 Printer Bluetooth

Yang dilakukan:

- membuat halaman setting printer
- menambahkan scan printer Bluetooth
- menyimpan printer default
- menghubungkan tombol cetak struk ke printer
- memperbaiki plugin printer lokal
- menyesuaikan proses print agar struk tidak terpotong

Hasil:

- printer Bluetooth berhasil terdeteksi
- test print berhasil
- struk berhasil tercetak

### 4.5 UI dan UX

Yang dirapikan:

- halaman legal pada register
- tombol dan card printer
- overflow notifikasi homepage
- top bar Buku Kas
- top bar Insert Hutang
- format rupiah di stats page
- fallback icon kategori pengeluaran

Hasil:

- tampilan aplikasi menjadi lebih konsisten
- angka uang lebih mudah dibaca
- pengalaman demo lebih baik

## 5. Hasil Akhir

Setelah seluruh proses:

- backend admin sudah berjalan di production
- mobile sudah bisa terhubung ke backend production
- fitur notifikasi sudah tersedia
- fitur forgot password OTP sudah tersedia
- fitur printer Bluetooth sudah berjalan
- banyak bug penting sudah diperbaiki
- UI utama sudah lebih konsisten

## 6. Kendala yang Dihadapi

Beberapa kendala selama proses:

- koneksi internet lambat membuat onboarding terasa stuck
- plugin printer bawaan tidak stabil
- scanner printer perlu penyesuaian permission dan plugin lokal
- ada warning analyzer yang masih tersisa
- beberapa fitur sensitif terhadap kondisi device dan jaringan

## 7. Strategi Demo

Agar demo aman dan lancar, strategi yang disarankan:

- tampilkan form daftar sebagai gambaran alur user baru
- gunakan akun demo yang sudah selesai onboarding
- hindari menjadikan onboarding live sebagai inti demo
- gunakan backend production, bukan lokal
- pastikan printer sudah dipilih di settings sebelum demo

## 8. Status Aplikasi Saat Ini

Status saat ini:

- aplikasi sudah layak untuk testing dan presentasi
- fitur inti sudah berjalan
- printer sudah berfungsi
- backend production sudah aktif

Namun:

- belum sepenuhnya 100% clean dari sisi `flutter analyze`
- masih ada warning dan info yang sebaiknya dirapikan jika ingin benar-benar final production

## 9. Kesimpulan

Secara keseluruhan, proses ini berhasil mengubah aplikasi dari kondisi yang masih banyak kendala teknis menjadi aplikasi yang:

- lebih stabil
- lebih siap demo
- sudah bisa digunakan untuk testing client
- sudah memiliki fitur penting seperti notifikasi, OTP reset password, dan cetak struk Bluetooth

Kesimpulan singkat untuk PPT:

- masalah utama berhasil diidentifikasi
- solusi teknis berhasil diterapkan
- fitur inti sudah berjalan
- aplikasi sudah berada pada tahap layak uji dan layak presentasi

