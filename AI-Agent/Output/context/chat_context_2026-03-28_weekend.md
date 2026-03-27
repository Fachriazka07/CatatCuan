# Chat Context - Weekend Focus

Tanggal dibuat: 28 Maret 2026  
Konteks ini dibuat untuk lanjut kerja di chat baru dengan fokus progres setelah Jumat, 27 Maret 2026, dan target kerja Sabtu-Minggu, 28-29 Maret 2026.

## 1. Posisi Project Saat Ini

Project: **CatatCuan Mobile**  
Target produk sekarang dipersempit jadi: **aplikasi pencatatan untuk warung**, bukan untuk semua UMKM.

Alasan keputusan ini:
- client nyata adalah nenek sendiri yang punya warung
- lebih kuat untuk kebutuhan ujikom
- flow produk jadi lebih konsisten
- copy UI jadi lebih jelas
- presentasi sidang jadi lebih mudah dijelaskan

Fokus UX:
- user warung usia 45+
- bahasa Indonesia saja
- UI sederhana, jelas, tidak banyak opsi yang membingungkan

## 2. Keputusan Produk yang Sudah Disepakati

- App difokuskan ke **warung**
- istilah `UMKM` / `usaha` tidak lagi ditonjolkan di UI
- onboarding `pilih usaha / business type` dihapus
- `Bahasa` di settings dihapus karena tidak relevan untuk target user
- `Pusat Bantuan` diarahkan langsung ke WhatsApp
- fitur advanced seperti SMS OTP, push notification Firebase, dan offline-first dianggap **fitur lanjutan**, bukan prioritas utama sebelum Senin

## 3. Progress Yang Sudah Dikerjakan Pada Jumat, 27 Maret 2026

### A. Laporan dan Stats
- wireframe `Laporan` sudah dibuat
- wireframe `Stats` sudah dibuat
- prompt Gemini CLI untuk `Laporan`, `Stats`, dan `Settings` sudah dibuat
- `Laporan` dan `Stats` diarahkan tetap konsisten dengan desain mobile CatatCuan
- `Laporan` dibedakan dari `Stats`:
  - `Laporan` fokus ke rekap dan export
  - `Stats` fokus ke insight dan trend

### B. Onboarding
- step `onboarding_business_type.dart` diputuskan tidak dipakai lagi
- onboarding difokuskan langsung ke konteks warung
- copy onboarding diubah ke istilah warung

### C. Settings
Halaman dan subhalaman settings yang sudah dibuat / dilengkapi:
- `Profil Saya`
- `Edit Profil`
- `Data Warung`
- `Edit Data Warung`
- `Ubah Password`
- `Periode Default`
- `Notifikasi`
- `Kategori Produk`
- `Kategori Pengeluaran`
- `Satuan Produk`
- `Saldo Awal`
- `Tentang Aplikasi`
- `Kebijakan Privasi`

Keputusan penting di settings:
- `Profil Saya` dipisah dari `Data Warung`
- `Data Warung` tidak memuat `Saldo Awal`
- `Saldo Awal` punya halaman sendiri
- `Pusat Bantuan` diarahkan ke WhatsApp `+62 878-2578-2889`
- `Bahasa` dihapus

### D. Ubah Password
- page `Ubah Password` sudah dibuat
- service Flutter untuk ubah password sudah dibuat
- migration SQL untuk RPC ubah password sudah dibuat:
  - `catatcuan-admin/migrations/change_mobile_user_password.sql`

Catatan:
- agar fitur ubah password benar-benar jalan, function SQL harus dijalankan dulu di Supabase SQL Editor

### E. Periode Default
- dibuat 1 setting global `Periode Default`
- opsi:
  - `Harian`
  - `Mingguan`
  - `Bulanan`
  - `Triwulanan`
- default awal diputuskan: **Bulanan**
- `Laporan` dan `Stats` harus sinkron membaca preferensi ini

### F. Notifikasi Settings
- halaman `Notifikasi` pakai switch toggle sudah dibuat
- opsi toggle:
  - `Pengingat Hutang Jatuh Tempo`
  - `Alert Stok Menipis`
  - `Pengingat Catat Hari Ini`
- preferensi disimpan di local `SharedPreferences`
- styling switch `OFF` sudah diubah jadi outline merah lembut
- styling switch `ON` diputuskan **tanpa outline**

### G. Home Page
Perubahan yang sudah dilakukan:
- tombol `Pusat Bantuan` di home bisa diklik dan direct ke WhatsApp
- icon notif di home punya badge jumlah notifikasi
- notifikasi stok menipis / habis sudah dibuat sebagai in-app notification
- popup daftar notifikasi dari icon lonceng sudah ada
- jarak icon notif dengan `Pusat Bantuan` dirapikan
- jarak `Transaksi Penjualan` ke `6 fitur` dirapikan sampai mendekat sesuai request user

Logika stok saat ini:
- stok `0` => `Produk habis. Segera stok ulang.`
- stok `< 3` dan `> 0` => `Stok tinggal X. Segera beli lagi.`

### H. Branding Aplikasi
- nama aplikasi Android di launcher diubah menjadi `CatatCuan`
- icon launcher Android diganti dari bawaan Flutter menjadi asset:
  - `catatcuan-mobile/assets/icon.png`

## 4. Hal Yang Masih Belum Final / Perlu Dicek Lagi

- pastikan function SQL `change_mobile_user_password` sudah benar-benar di-deploy ke Supabase
- cek semua route baru settings lewat hot restart / full restart
- pastikan icon launcher Android sudah tampil benar di HP
- cek styling final switch di halaman `Notifikasi`
- cek apakah `Laporan` dan `Stats` benar-benar membaca `Periode Default` yang sama
- audit ulang istilah `warung` agar tidak ada sisa copy `usaha/UMKM` yang masih tampil ke user

## 5. Fokus Kerja Sabtu, 28 Maret 2026

Fokus Sabtu adalah **menentukan apakah mau lanjut ke backend advanced atau tetap menutup core mobile dulu**.

Urutan yang disarankan:

### Prioritas 1
Tutup semua fitur mobile yang masih setengah jadi atau masih ada bug visual / route / logic kecil:
- cek `Settings`
- cek `Laporan`
- cek `Stats`
- cek `Home`

### Prioritas 2
Kalau core mobile sudah cukup stabil, mulai masuk ke backend untuk 2 service advanced:
- service notifikasi push
- service reset password / SMS OTP

Catatan penting:
- dua fitur ini butuh backend aktif
- notifikasi push idealnya pakai Firebase + backend trigger
- SMS reset password tidak pakai Supabase Auth email, tapi lewat service eksternal dan backend
- kalau terlalu makan waktu, ini bisa diturunkan statusnya jadi bonus feature

## 6. Fokus Kerja Minggu, 29 Maret 2026

Fokus Minggu: **QA, bug fixing, dan stabilisasi**

Checklist yang disarankan:
- testing semua flow utama
- cek route baru
- cek error toast / dialog / empty state
- cek data masuk ke Supabase dengan benar
- cek hasil perhitungan di `Laporan` dan `Stats`
- cek `Buku Kas`, `Pengeluaran`, `Penjualan`, `Hutang/Piutang`
- cek settings satu per satu
- rapikan UI yang masih janggal

Kalau waktu cukup:
- mulai siapkan bahan presentasi
- catat fitur utama yang mau ditunjukkan saat demo
- catat bagian yang masih jadi pengembangan lanjutan

## 7. Target Utama Sebelum Senin

Target utama:
- **Senin aplikasi inti sudah beres**
- setelah itu fokus pindah ke:
  - laporan proyek
  - PPT
  - persiapan demo
  - latihan presentasi sidang

## 8. Fitur Yang Dianggap Bonus, Bukan Wajib Sebelum Senin

- Firebase push notification
- SMS OTP reset password
- offline-first / sync kompleks
- multi-language
- fitur advanced production hardening

## 9. Catatan Penting Untuk Chat Baru

Kalau lanjut di chat baru, asumsikan hal-hal berikut sudah dipahami:
- project sudah fokus ke **warung**
- user tidak mau fitur `Bahasa`
- `Pusat Bantuan` harus tetap direct ke WhatsApp
- `Settings` adalah fokus besar yang sudah banyak dikerjakan
- target sekarang bukan nambah ide besar baru, tapi **menutup fitur, merapikan bug, dan siap demo**
- Sabtu fokus ke penyelesaian core + kalau sempat backend advanced
- Minggu fokus ke testing dan stabilisasi

