# Chat Context Summary - 2026-03-25

## Ringkasan Umum

Chat ini berfokus pada stabilisasi project `CatatCuan`, perbaikan flow kas, dan implementasi awal fitur **Buku Kas** di mobile. Selain itu ada beberapa perbaikan penting di admin dashboard, onboarding, auth, detail user/warung, dan UX input nominal.

Project saat ini sudah sampai tahap:
- admin dashboard monitoring makin matang
- mobile flow kas lebih konsisten
- fitur `Buku Kas` sudah dibuat dan bisa dipakai
- beberapa bug penting di checkout, pengeluaran, hutang, dan onboarding sudah dibereskan

---

## Yang Sudah Dikerjakan

### 1. Admin Dashboard

- Menambahkan halaman **Detail User** dan **Detail Warung** dengan desain yang konsisten.
- Menambahkan komponen shared untuk tampilan detail admin.
- Menambahkan tombol `Detail` di list user/warung.
- Mengubah list agar seluruh baris bisa diklik, tanpa ikon panah dan menu aksi yang mengganggu.
- Memperbaiki status user:
  - `active`
  - `inactive`
  - `suspended`
- Memperbaiki styling tombol status user agar tidak terbalik.
- Menambahkan dan memperbaiki `last_login_at`.
- Menambahkan activity logging admin ke `SYSTEM_LOGS`.
- Menjadikan admin dashboard lebih fokus ke monitoring, bukan CRUD user/warung.
- Menghapus flow tambah/edit user dari admin list monitoring.

### 2. Supabase / Security / Auth

- Menyiapkan phase 1 RLS rollout untuk tabel admin dan master data.
- Menyesuaikan RLS agar role admin dibaca dari `auth.users.raw_app_meta_data`.
- Menjelaskan penggunaan `role = admin/superadmin` pada Supabase Auth.
- Menambahkan migration untuk hash password mobile user.
- Mengubah flow register/login mobile agar tidak lagi mengandalkan plaintext password di tabel `USERS`.

### 3. Onboarding / Register / Duplicate Warung

- Menemukan bug onboarding yang bisa membuat warung duplicate saat tombol selesai ditekan berulang.
- Memperbaiki onboarding agar submit tidak dobel.
- Mengubah flow agar jika warung user sudah ada maka dilakukan update, bukan insert baru.
- Menambahkan helper SQL untuk cleanup duplicate warung dan enforce 1 user = 1 warung.
- Menambahkan loading state pada tombol `Selesai` onboarding agar tidak terasa seperti app freeze.

### 4. UX Input Nominal

- Menambahkan format ribuan pada input nominal:
  - hutang
  - produk
  - pengeluaran
  - checkout
- Menyamakan UX agar field nominal menampilkan prefix `Rp` secara konsisten.
- Memperbaiki bug close button ketika input nominal sedang fokus di web.

### 5. Checkout / Penjualan / Hutang

- Memperbaiki checkout agar tombol tambah qty mengikuti validasi stok seperti POS cashier.
- Menjadikan `Jatuh Tempo` kasbon/hutang sebagai field opsional.
- Menambahkan `catatan` otomatis ke data hutang dari hasil transaksi produk.
- Format catatan hutang sekarang berisi daftar produk, qty, dan subtotal.
- Memperbaiki detail hutang agar catatan multiline tampil rapi.

### 6. Buku Kas

- Mengecek planning, design, use case, wireframe, dan schema lama.
- Memastikan `Buku Kas` memang fitur yang direncanakan sejak awal.
- Menambahkan fitur mobile:
  - `buku_kas_page.dart`
  - `uang_masuk_page.dart`
  - `uang_keluar_page.dart`
  - `transfer_page.dart`
  - `adjustment_page.dart`
- Menambahkan popup FAB Buku Kas:
  - Transaksi
  - Transfer/Pemindahan
  - Penyesuaian Saldo
- Menjadikan bagian `Transaksi` expandable untuk:
  - `Uang Masuk`
  - `Uang Keluar`
- Menambahkan migration enum untuk source cash flow baru.

### 7. Integrasi Buku Kas dengan Flow Nyata

- Memperbaiki agar transaksi penjualan masuk ke `BUKU_KAS`.
- Memperbaiki agar pengeluaran masuk ke `BUKU_KAS`.
- Memperbaiki agar pembayaran hutang/piutang masuk ke `BUKU_KAS`.
- Memperbaiki logika kasbon:
  - jika customer berhutang, saldo kas tidak langsung bertambah penuh
  - hanya uang yang benar-benar diterima saat transaksi yang masuk kas
  - sisanya baru masuk saat dibayar

### 8. Pengeluaran

- Menyederhanakan flow pengeluaran.
- Menghapus pilihan `Kas Opr` dari UI input pengeluaran karena membingungkan.
- Menjadikan pengeluaran fokus ke **uang warung**.
- Merapikan card `Diambil Dari` agar lebih konsisten dan tidak terlihat rusak.
- Mengubah logika pengeluaran supaya validasi dan pemotongan saldo mengikuti total uang warung.

### 9. Tanggal / Timezone

- Menemukan bug tampilan hari/tanggal yang meleset di Home dan Buku Kas.
- Akar masalah: penyimpanan `DateTime` ke `timestamptz` tidak konsisten.
- Memperbaiki beberapa flow agar timestamp disimpan dengan UTC eksplisit:
  - checkout
  - pengeluaran
  - pembayaran hutang
  - buku kas manual
  - transfer
  - adjustment

---

## Keputusan Penting yang Diambil

### Admin

- Admin dashboard diposisikan sebagai **monitoring tool**, bukan tempat utama CRUD entitas bisnis.
- Detail user/warung boleh menampilkan data operasional yang relevan selama tidak membocorkan password/token/data sensitif.

### Buku Kas

- Buku Kas dijalankan sebagai **ledger kas warung**.
- Untuk kasbon/hutang:
  - uang yang belum dibayar **bukan kas masuk**
  - hanya DP atau pembayaran aktual yang menambah kas

### Pengeluaran

- Untuk versi sekarang, pengeluaran difokuskan ke uang warung.
- `uang_kas_operasional` tidak dihapus dari database dulu, tapi dihilangkan dari UX agar tidak membingungkan user.

---

## File Penting yang Sudah Banyak Diubah

### Mobile

- `catatcuan-mobile/lib/features/penjualan/checkout_page.dart`
- `catatcuan-mobile/lib/features/hutang/detail_hutang.dart`
- `catatcuan-mobile/lib/core/services/hutang_service.dart`
- `catatcuan-mobile/lib/features/pengeluaran/insert_pengeluaran.dart`
- `catatcuan-mobile/lib/features/pengeluaran/detail_pengeluaran.dart`
- `catatcuan-mobile/lib/features/buku_kas/buku_kas_page.dart`
- `catatcuan-mobile/lib/features/buku_kas/transaction/uang_masuk_page.dart`
- `catatcuan-mobile/lib/features/buku_kas/transaction/uang_keluar_page.dart`
- `catatcuan-mobile/lib/features/buku_kas/transfer/transfer_page.dart`
- `catatcuan-mobile/lib/features/buku_kas/adjustment/adjustment_page.dart`
- `catatcuan-mobile/lib/core/router/app_router.dart`

### Admin

- `catatcuan-admin/src/app/dashboard/users/UserSearch.tsx`
- `catatcuan-admin/src/app/dashboard/users/[id]/page.tsx`
- `catatcuan-admin/src/app/dashboard/warungs/[id]/page.tsx`
- `catatcuan-admin/src/components/admin/user-status-actions.tsx`
- `catatcuan-admin/src/components/admin/entity-detail.tsx`
- `catatcuan-admin/src/components/admin/status-badge.tsx`

### SQL / Migration

- `catatcuan-admin/migrations/update_cash_flow_source_enum.sql`
- `catatcuan-admin/migrations/hash_mobile_user_passwords.sql`
- `catatcuan-admin/migrations/phase1_enable_rls_admin_and_master_tables.sql`
- helper cleanup duplicate warung / unique warung per user

---

## Commit Terakhir yang Dibuat

- Commit hash: `5b9f8ca`
- Message:

`feat: add buku kas flow and align cash transaction logic`

---

## Yang Masih Perlu Dicek / Next Step

### 1. Testing Manual

Perlu dites ulang di app/device:
- transaksi tunai
- transaksi kasbon tanpa DP
- transaksi kasbon dengan DP
- tambah pengeluaran
- edit pengeluaran
- bayar hutang/piutang
- buku kas manual masuk/keluar
- transfer saldo
- adjustment saldo

### 2. Data Lama

- Row lama di `BUKU_KAS`, `PENGELUARAN`, atau transaksi lain mungkin masih punya timestamp yang salah timezone.
- Bisa perlu SQL one-time fix jika data historis ingin dibersihkan.

### 3. Penyederhanaan Istilah Uang

Istilah yang disarankan untuk konsistensi:
- `Uang Warung` = total
- `Uang Laci` = saldo awal/laci
- `Uang Kas` = kas aktif

Masih perlu audit seluruh mobile supaya semua page memakai istilah yang sama.

### 4. Validasi Buku Kas

Masih perlu audit:
- apakah semua flow yang gerakin uang sudah benar-benar insert jurnal
- apakah saldo setelah (`saldo_setelah`) sudah selalu sinkron
- apakah edit/hapus transaksi lama perlu rollback buku kas yang lebih lengkap

---

## Kesimpulan

Pada akhir chat ini:
- fitur **Buku Kas** sudah dibuat dan terhubung
- flow kas penjualan, hutang, dan pengeluaran sudah jauh lebih benar
- admin monitoring sudah lebih matang
- UX nominal, status user, onboarding, dan beberapa bug lama sudah diperbaiki

Ini sudah jadi fondasi yang jauh lebih stabil untuk lanjut ke tahap penyempurnaan Buku Kas, audit saldo, dan polishing akhir aplikasi.
