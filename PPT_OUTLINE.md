# Outline PPT

## Judul Utama

**Aplikasi Sistem Manajemen Keuangan dan Inventori Berbasis Mobile**

Subjudul opsional:

- Studi kasus implementasi pada aplikasi `CatatCuan`

## 1. Latar Belakang

Bagian ini jangan langsung menyebut `CatatCuan`, tetapi bahas masalah umum terlebih dahulu.

Poin yang bisa dipakai:

- Banyak usaha kecil dan warung masih melakukan pencatatan keuangan secara manual.
- Pencatatan manual sering menyebabkan data penjualan, pengeluaran, dan stok tidak tersusun dengan rapi.
- Pemilik usaha kesulitan memantau arus kas, stok barang, dan hutang pelanggan secara cepat.
- Dibutuhkan sistem berbasis mobile yang dapat membantu pengelolaan keuangan dan inventori secara lebih efisien.

Versi singkat untuk slide:

- Pencatatan usaha kecil masih banyak dilakukan secara manual
- Data keuangan dan stok sulit dipantau secara real time
- Diperlukan sistem mobile yang praktis, terintegrasi, dan mudah digunakan

## 2. Tujuan

Poin tujuan:

- Membuat sistem manajemen keuangan dan inventori berbasis mobile
- Membantu proses pencatatan transaksi, pengeluaran, buku kas, dan stok barang
- Mempermudah pemilik usaha dalam memantau kondisi usaha
- Menyediakan sistem yang lebih efektif, rapi, dan mudah digunakan dibanding pencatatan manual

Versi singkat untuk slide:

- Membuat sistem pencatatan usaha berbasis mobile
- Mengelola keuangan dan inventori secara digital
- Membantu pemilik usaha memantau data dengan lebih cepat dan akurat

## 3. Perancangan Sistem

Bagian ini menjelaskan arsitektur sistem secara umum.

Poin yang bisa dijelaskan:

- Sistem terdiri dari aplikasi mobile untuk pengguna dan admin panel untuk pengelolaan sistem
- Aplikasi mobile digunakan untuk transaksi, pengeluaran, buku kas, hutang, statistik, dan stok
- Admin panel digunakan untuk monitoring user, notifikasi, pengaturan sistem, dan layanan backend
- Data disimpan dalam database cloud sehingga dapat diakses secara terintegrasi

Kalimat presentasi:

"Sistem dirancang dengan arsitektur client-server. Sisi client berupa aplikasi mobile yang digunakan pengguna, sedangkan sisi server dikelola melalui admin panel dan database cloud untuk mendukung sinkronisasi data, notifikasi, dan proses backend lainnya."

## 4. Teknologi yang Digunakan

Teknologi yang dapat disebut:

- `Flutter`
  - untuk pengembangan aplikasi mobile
- `Next.js`
  - untuk admin panel dan backend web
- `Supabase`
  - untuk database dan layanan backend
- `Firebase Cloud Messaging`
  - untuk push notification
- `Twilio Verify`
  - untuk OTP reset password
- `Vercel`
  - untuk deployment admin panel
- `Bluetooth Thermal Printer`
  - untuk fitur cetak struk

Kalau ingin dibuat singkat:

- Flutter
- Next.js
- Supabase
- Firebase
- Twilio
- Vercel
- Bluetooth Printer

## 5. Aplikasi yang Dibuat

Di bagian inilah kamu mulai memperkenalkan aplikasi `CatatCuan`.

Poin yang bisa dipakai:

- Nama aplikasi: `CatatCuan`
- Jenis aplikasi: sistem manajemen keuangan dan inventori berbasis mobile
- Target pengguna:
  - pemilik warung
  - usaha kecil
  - toko rumahan
- Fungsi utama aplikasi:
  - pencatatan transaksi penjualan
  - pencatatan pengeluaran
  - pengelolaan buku kas
  - pengelolaan produk dan stok
  - pengelolaan hutang
  - statistik usaha
  - notifikasi pengingat
  - cetak struk Bluetooth

Kalimat presentasi:

"Aplikasi yang saya buat bernama CatatCuan. CatatCuan merupakan aplikasi sistem manajemen keuangan dan inventori berbasis mobile yang ditujukan untuk membantu pemilik warung atau usaha kecil dalam mengelola aktivitas usaha secara digital."

## 6. Masalah yang Ditemukan Dalam Pengembangan

Bagian ini menjelaskan masalah selama proses pembuatan sistem.

Poin yang bisa disampaikan:

- Kesulitan mengatur sistem notifikasi pengingat agar berjalan konsisten
- Notifikasi kadang muncul semua, tetapi pada kondisi lain tidak muncul sama sekali
- Integrasi printer Bluetooth awalnya masih sulit pada proses deteksi perangkat dan pencetakan struk
- Hasil cetak struk sempat tidak stabil dan ada bagian yang terpotong
- Kesulitan menjaga konsistensi tampilan dan responsive aplikasi di berbagai halaman dan perangkat
- Beberapa halaman sempat mengalami overflow, tabrakan dengan status bar, dan tampilan yang belum seragam

Versi singkat untuk slide:

- Sistem notifikasi pengingat belum konsisten
- Integrasi printer Bluetooth masih mengalami kendala
- Konsistensi tampilan dan responsive aplikasi belum optimal

## 7. Solusi

Bagian ini menjelaskan solusi dari masalah tadi.

Poin yang bisa dipakai:

- Melakukan penyesuaian pada alur pengiriman notifikasi dan reminder agar sistem notifikasi menjadi lebih stabil
- Menyediakan mekanisme pengujian notifikasi agar proses pengecekan lebih mudah dilakukan
- Mengembangkan fitur printer Bluetooth dengan proses scan perangkat, pengaturan printer, dan penyesuaian alur cetak struk
- Melakukan perbaikan pada proses pencetakan agar hasil struk dapat tercetak lebih baik
- Merapikan tampilan aplikasi pada berbagai halaman agar lebih konsisten dan responsive di berbagai perangkat
- Memperbaiki overflow, header, dan susunan elemen antarmuka agar pengalaman pengguna lebih baik

Versi singkat untuk slide:

- Menstabilkan sistem notifikasi pengingat
- Menyempurnakan fitur printer Bluetooth dan cetak struk
- Merapikan tampilan agar lebih konsisten dan responsive

## 8. Demo Page

Di bagian ini kamu jelaskan halaman-halaman yang akan didemokan.

Urutan demo yang aman:

1. Login / Register
2. Home Page
3. Produk
4. Penjualan
5. Checkout dan Receipt
6. Cetak Struk Bluetooth
7. Pengeluaran
8. Buku Kas
9. Statistik
10. Notifikasi

Kalimat presentasi:

"Pada sesi demo, saya akan menunjukkan alur utama aplikasi mulai dari login, pengelolaan produk, transaksi penjualan, cetak struk, pengeluaran, buku kas, statistik, hingga notifikasi."

## 9. Kesimpulan

Poin kesimpulan:

- Sistem manajemen keuangan dan inventori berbasis mobile berhasil dirancang dan diimplementasikan
- Aplikasi mampu membantu pencatatan transaksi, pengeluaran, buku kas, stok, dan hutang secara digital
- Sistem backend dan notifikasi sudah terintegrasi
- Fitur cetak struk Bluetooth juga berhasil ditambahkan
- Aplikasi sudah layak digunakan untuk demo dan pengujian lebih lanjut

Versi singkat untuk slide:

- Sistem berhasil dibangun berbasis mobile
- Fitur utama keuangan dan inventori telah berjalan
- Aplikasi membantu digitalisasi pencatatan usaha kecil

## 10. Penutup

Kalimat penutup:

**Terima kasih.**

**Saya siap menerima pertanyaan.**
