# Rangkuman Pengerjaan CatatCuan

Dokumen ini merangkum seluruh alur chat dan pengerjaan dari awal sampai kondisi terbaru, mencakup backend admin, mobile app, deploy, printer Bluetooth, notifikasi, perbaikan UI, dan status kesiapan aplikasi.

## 1. Gambaran Umum

Project yang dikerjakan terdiri dari:

- `catatcuan-admin`
  - Backend/admin panel berbasis Next.js
  - Menangani dashboard admin, notifikasi, OTP reset password, cron reminder, dan deploy ke Vercel
- `catatcuan-mobile`
  - Aplikasi Flutter untuk user warung
  - Menangani onboarding, transaksi, pengeluaran, buku kas, statistik, notifikasi, cetak struk Bluetooth, dan flow auth

Fokus utama selama chat:

- menyelesaikan backend admin dan deploy production
- menyambungkan mobile ke backend production
- menambahkan dan memperbaiki fitur notifikasi
- memperbaiki error Flutter/analyze
- menambahkan halaman legal
- menambahkan dan menstabilkan fitur printer Bluetooth
- merapikan berbagai UI yang bermasalah

## 2. Backend Admin

### 2.1 Fitur yang dikerjakan

Di `catatcuan-admin`, fitur-fitur utama yang dikerjakan dan disiapkan:

- mobile backend API
- push notification dispatch
- password reset berbasis Twilio Verify
- OTP forgot password
- route internal notifikasi
- route cron reminder pagi dan malam
- test panel notifikasi di halaman konfigurasi admin

File yang berkaitan dan sempat jadi fokus:

- `src/lib/twilio-verify.ts`
- `src/lib/password-reset-service.ts`
- `src/lib/notification-service.ts`
- `src/lib/sms-provider.ts`
- `src/app/api/cron/...`
- `src/app/dashboard/config/page.tsx`

### 2.2 Commit yang sudah dibuat

Sempat dibuat commit dengan hash:

- `021bad7`

Pesan commit:

- `feat: add mobile notifications and password reset flows`

## 3. Deploy Admin ke Vercel

### 3.1 Langkah deploy yang dibahas

Deploy `catatcuan-admin` diarahkan ke Vercel dengan flow:

1. push code ke GitHub
2. import project ke Vercel
3. set root directory ke `catatcuan-admin`
4. isi environment variables
5. deploy
6. ambil URL production
7. sambungkan mobile ke URL production tersebut

### 3.2 Environment variables yang dibahas

Environment yang dipakai mencakup:

- Supabase URL dan anon key
- `DATABASE_URL`
- secret backend mobile
- secret dispatch notifikasi
- kredensial Firebase
- mode SMS provider
- Twilio SID, token, dan Verify service SID

Catatan penting yang dibahas:

- `DATABASE_URL` sebaiknya memakai pooler Supabase
- tambahkan `?sslmode=require`
- `FIREBASE_SERVICE_ACCOUNT_JSON` tidak perlu dipakai jika sudah memecah menjadi:
  - `FIREBASE_PROJECT_ID`
  - `FIREBASE_CLIENT_EMAIL`
  - `FIREBASE_PRIVATE_KEY`

### 3.3 Domain production

Domain production backend admin yang akhirnya dipakai:

- `https://catat-cuan-admin.vercel.app`

### 3.4 Catatan keamanan

Beberapa hal yang ditekankan:

- Vercel env aman untuk secret server-side
- jangan commit `.env.local`
- `NEXT_PUBLIC_*` dianggap publik
- secret yang sempat tampil di screenshot/chat tetap sebaiknya di-rotate setelah deploy stabil

## 4. Koneksi Mobile ke Backend Production

### 4.1 Perubahan mobile env

File mobile yang diubah:

- `catatcuan-mobile/.env`

Yang paling penting:

- `MOBILE_BACKEND_BASE_URL` diarahkan ke URL Vercel production
- `MOBILE_BACKEND_API_KEY` disamakan dengan backend

Kesimpulan saat itu:

- mobile sudah bisa jalan tanpa backend lokal
- tinggal test login, token push, notif, forgot password, dan reminder

## 5. Catatan Testing Manual Notifikasi

Sempat dibahas script PowerShell untuk test manual:

- due date reminder
- low stock alerts
- daily reminders

Lalu script itu diubah agar:

- tidak lagi pakai `localhost`
- memakai base URL production Vercel
- lebih rapi untuk disimpan di notepad/code

Juga sempat disarankan untuk:

- menyimpan sebagai file `.ps1`
- atau membuat panel test langsung di admin

## 6. Panel Test Notifikasi di Admin

Fitur panel test notifikasi sempat ditambahkan ke halaman konfigurasi admin:

- `Push Manual`
  - isi `User ID`, judul, isi notif sendiri
- `Reminder Hutang Jatuh Tempo`
- `Alert Stok Menipis / Habis`
- `Pengingat Catat Hari Ini`

Tujuannya:

- memudahkan demo
- tidak perlu copy paste request manual
- menjaga secret dispatch tetap di server-side

## 7. Masalah Timezone di Admin Dashboard

Masalah yang ditemukan:

- jam daftar user di admin tidak sesuai waktu lokal
- data terlihat seperti UTC, bukan WIB

Perbaikan:

- formatter admin disesuaikan ke `Asia/Jakarta`
- beberapa file tampilan tanggal/jam admin dirapikan

Hasil yang diharapkan:

- waktu daftar user dan waktu update tampil sesuai WIB

## 8. APK dan Masalah Aplikasi "Berbahaya"

Pembahasan penting:

- peringatan saat install APK tidak selalu berarti aplikasi berbahaya
- biasanya karena:
  - sideload APK manual
  - APK debug
  - belum punya reputasi di Play Store

Saran yang diberikan:

- build `release APK` atau `AAB`
- sign dengan keystore sendiri
- gunakan package name yang konsisten
- distribusikan lewat Play Store internal testing jika ingin terlihat lebih meyakinkan

## 9. Masalah Supabase di APK

Saat dibahas dulu APK sempat terasa seperti "Supabase error".

Kandidat utama yang ditemukan:

- permission internet di Android belum ada
- build lama mungkin masih menunjuk ke backend lokal atau HTTP non-production

Perbaikan:

- menambahkan permission internet pada Android manifest
- memastikan backend mobile sudah memakai URL production

## 10. Perbaikan Error Flutter

### 10.1 Buku Kas

Di `buku_kas_page.dart`, sempat ada error type seperti:

- `The argument type 'dynamic' can't be assigned to the parameter type 'String'`

Perbaikan yang dilakukan:

- helper parsing aman untuk string dan number
- data Supabase tidak lagi dipakai mentah sebagai `dynamic`

Hasil:

- error merah di file buku kas beres

### 10.2 Error Analyzer Project

Sempat ada banyak error di:

- `stats_service.dart`
- `checkout_page.dart`
- `receipt_page.dart`
- dan beberapa file lain

Perbaikan yang dilakukan:

- mengetatkan parsing dari `dynamic`
- memastikan nilai `String`, `num`, dan map diproses aman
- menghapus import yang tidak dipakai

Hasil:

- error compile hilang
- tersisa warning dan info

## 11. Halaman Legal pada Register

Fitur yang diminta:

- halaman `Syarat & Ketentuan`
- halaman `Privasi Kami`
- keduanya bisa diakses dari register page

Yang dilakukan:

- menambahkan page terms
- menghubungkan page privacy yang sudah ada
- menambahkan route
- membuat teks legal di halaman register bisa ditap
- underline kemudian dihapus sesuai permintaan

## 12. Onboarding Lambat / Stuck di "Menyimpan..."

Masalah yang sempat muncul:

- setelah mengisi data warung dan modal awal, aplikasi seperti stuck di loading
- belakangan disimpulkan sangat dipengaruhi koneksi internet lambat

Optimasi yang dilakukan:

- flow onboarding diringankan
- data inti disimpan dulu
- preload cache dipindah ke background
- navigasi ke home tidak menunggu seluruh preload selesai

Kesimpulan:

- di rumah aman
- di lingkungan sekolah yang koneksinya jelek bisa terasa lambat
- disarankan tidak menjadikan onboarding live sebagai inti demo

## 13. Strategi Demo Sidang

Saran demo yang dibahas:

1. tunjukkan form daftar
2. jelaskan user baru akan melanjutkan isi data warung
3. login memakai akun demo yang sudah selesai onboarding
4. fokus demo ke fitur inti

Tujuannya:

- mengurangi risiko stuck saat koneksi sekolah buruk
- menjaga demo tetap lancar

## 14. Fitur Printer Bluetooth

Ini salah satu bagian paling panjang dan paling banyak iterasinya.

### 14.1 Kebutuhan awal

User punya printer struk Bluetooth dan ingin:

- cetak struk dari receipt page
- ada halaman setting printer
- aplikasi bisa mendeteksi printer
- ada test print

### 14.2 Implementasi awal

Awalnya receipt page hanya placeholder:

- tombol `CETAK STRUK` belum benar-benar mencetak

Lalu dibangun:

- service printer Bluetooth
- halaman settings printer
- penyimpanan printer default
- integrasi tombol `CETAK STRUK`

File utama yang terkait:

- `lib/core/services/bluetooth_printer_service.dart`
- `lib/core/services/printer_settings_service.dart`
- `lib/features/settings/printer_settings_page.dart`
- `lib/features/penjualan/receipt_page.dart`

### 14.3 Masalah yang muncul

Masalah yang sempat ditemui:

- printer tidak muncul
- permission nearby devices/location
- plugin scanner Android bermasalah
- plugin thermal lama crash
- `lateinit property bluetoothService has not been initialized`
- Android 34 / `PendingIntent` issue
- layout error di page printer
- tombol printer terlalu sempit
- beberapa log MIUI membingungkan

### 14.4 Perubahan teknis penting

Perubahan yang dilakukan selama iterasi:

- menambahkan permission Bluetooth dan lokasi
- mengganti pendekatan dari paired list ke scan Bluetooth
- menambahkan fallback input manual MAC address
- lalu kembali diperbaiki ke flow scan yang lebih natural
- membuat plugin lokal `printer_service` di `third_party`
- memperbaiki plugin lokal agar tidak crash saat Firebase background engine berjalan
- memperbaiki inisialisasi Bluetooth service secara lazy
- membatasi init USB agar tidak merusak background engine

### 14.5 Hasil akhir printer

Akhirnya user mengonfirmasi:

- printer berhasil jalan
- struk berhasil tercetak

Kalimat penting dari user:

- "AKHIRNYA JALAN STRUKNYA"

### 14.6 Pemotongan bagian bawah struk

Masalah lanjutan:

- hasil print terpotong di bawah
- subtotal, total, kembalian, dan "Terima Kasih" tidak ikut tercetak penuh

Perbaikan yang dilakukan:

- menghapus `cut()` yang tidak cocok untuk printer thermal murah
- menambah feed di akhir
- memberi jeda sebelum disconnect printer

### 14.7 UI receipt page

Masalah UI juga sempat muncul:

- bagian bawah receipt page di layar tidak terlihat penuh karena tertutup bottom action

Perbaikan:

- menambah bottom padding dinamis pada konten scroll

### 14.8 Perbaikan button di halaman printer

Masalah:

- tombol `Dipilih` gepeng dan turun ke dua baris

Perbaikan:

- memperlebar tombol
- membuat teks scale down

## 15. Perbaikan UI Lain

### 15.1 Notification bottom sheet di homepage

Masalah:

- overflow di daftar notifikasi

Perbaikan:

- tinggi dibuat lebih terkontrol
- isi list benar-benar scrollable
- nama produk dan deskripsi diberi `maxLines`

### 15.2 Top bar Buku Kas

Masalah:

- top bar belum full seperti halaman lain

Perbaikan:

- penyesuaian tinggi sesuai status bar
- header disamakan dengan pola halaman lain

### 15.3 Top bar Insert Hutang

Masalah:

- top bar tabrakan dengan status bar HP

Perbaikan:

- menyesuaikan dengan status bar
- membuat header konsisten dengan page lain

## 16. Stats Page

Permintaan:

- angka uang di stats page dibuat lebih enak dibaca dalam format rupiah

Perbaikan:

- nominal KPI tetap dalam format rupiah
- sumbu kiri chart memakai format rupiah ringkas
- tooltip chart garis menampilkan nominal penuh
- tooltip bar chart arus kas juga menampilkan nominal penuh

## 17. Pengeluaran List dan Icon Fallback

Permintaan:

- untuk kategori pengeluaran yang belum punya icon sendiri, list pengeluaran memakai fallback `Lainya.png`

Perbaikan:

- pada `pengeluaran_list.dart`, jika icon kategori tidak ada di folder pengeluaran, otomatis pakai:
  - `assets/icon/produk-icon/Lainya.png`

Hasil:

- kategori seperti `Belanja Stok` dan kategori lain yang belum punya icon khusus tetap tampil rapi dan konsisten

## 18. Status Analyzer Terakhir

Setelah berbagai perbaikan, `flutter analyze` sempat dicek kembali.

Status terakhir:

- tidak ada error merah
- masih ada warning dan info
- total issue terakhir yang tercatat: `60 issues`

Maknanya:

- aplikasi cukup layak untuk testing/UAT
- belum bisa disebut bersih total secara analyzer
- masih ada pekerjaan quality cleanup jika ingin benar-benar rapi

Issue yang masih banyak berupa:

- warning inference
- warning raw type
- warning async context
- beberapa deprecated API
- beberapa lint style

## 19. Status Kelayakan Aplikasi

Kesimpulan yang sempat diberikan:

- layak untuk `client testing` atau `UAT`
- belum diberi cap `100% final production-clean`

Kenapa belum 100%:

- analyzer masih punya warning/info
- build final release belum diverifikasi bersih end-to-end dalam chat ini
- masih ada area yang layak dibersihkan untuk kualitas jangka panjang

## 20. Catatan Penting Soal `third_party`

Ada keinginan untuk menghapus folder `third_party` karena dianggap hanya untuk testing.

Namun hasil pengecekan menunjukkan:

- `third_party/printer_service` masih dipakai aktif oleh aplikasi
- `pubspec.yaml` memakai `dependency_overrides` ke package lokal tersebut
- service printer di app mengimport package itu

Jadi kesimpulannya:

- folder `third_party` tidak bisa dihapus total
- kalau dihapus, fitur printer berisiko rusak
- yang aman adalah mengecualikan folder itu dari analyzer root atau membersihkan folder contoh/test di dalamnya

## 21. File-FIle Penting yang Sering Tersentuh

### Admin

- `catatcuan-admin/src/lib/twilio-verify.ts`
- `catatcuan-admin/src/lib/password-reset-service.ts`
- `catatcuan-admin/src/lib/notification-service.ts`
- `catatcuan-admin/src/lib/sms-provider.ts`
- `catatcuan-admin/src/app/dashboard/config/page.tsx`
- `catatcuan-admin/src/app/api/cron/evening-daily-reminder/route.ts`

### Mobile

- `catatcuan-mobile/.env`
- `catatcuan-mobile/android/app/src/main/AndroidManifest.xml`
- `catatcuan-mobile/lib/features/buku_kas/buku_kas_page.dart`
- `catatcuan-mobile/lib/features/hutang/insert_hutang.dart`
- `catatcuan-mobile/lib/features/pengeluaran/pengeluaran_list.dart`
- `catatcuan-mobile/lib/features/penjualan/checkout_page.dart`
- `catatcuan-mobile/lib/features/penjualan/receipt_page.dart`
- `catatcuan-mobile/lib/features/settings/printer_settings_page.dart`
- `catatcuan-mobile/lib/features/stats/presentation/pages/stats_page.dart`
- `catatcuan-mobile/lib/core/services/bluetooth_printer_service.dart`
- `catatcuan-mobile/lib/core/services/printer_settings_service.dart`
- `catatcuan-mobile/lib/core/services/stats_service.dart`
- `catatcuan-mobile/analysis_options.yaml`
- `catatcuan-mobile/pubspec.yaml`

### Plugin Lokal Printer

- `catatcuan-mobile/third_party/printer_service/...`

## 22. Kesimpulan Akhir

Secara keseluruhan, progres selama chat ini sudah sangat besar:

- backend admin sudah disiapkan dan dideploy ke production
- mobile sudah diarahkan ke backend production
- fitur notifikasi dan OTP reset password sudah dibangun
- banyak bug dan error Flutter sudah dibereskan
- printer Bluetooth sudah berhasil jalan
- UI penting sudah banyak dirapikan

Status saat dokumen ini dibuat:

- aplikasi sudah berada di tahap layak uji / layak dipresentasikan / layak diberikan untuk testing client
- tetapi belum bisa disebut 100% clean dari sisi analyzer dan hardening final

Jika ingin benar-benar final sebelum serah ke client, langkah saran berikutnya:

1. rapikan warning analyzer paling penting
2. jalankan build release final
3. test ulang fitur-fitur inti pada APK release
4. rotate secret yang sempat terekspos selama proses setup/deploy
5. commit dan tag versi final

