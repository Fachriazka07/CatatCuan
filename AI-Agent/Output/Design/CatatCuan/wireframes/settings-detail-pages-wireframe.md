# CatatCuan - Settings Detail Pages Wireframe

**Version:** 1.0  
**Date:** 2026-03-27  
**Fidelity:** Mid-Fi (Layout + UX behavior)  
**Platform:** Mobile-First (Flutter)  
**Scope:** Seluruh isi dan subpage dari menu `Settings`

---

## 1. Overview

Dokumen ini melengkapi `settings-page-wireframe.md` dengan detail semua isi halaman `Settings` dan subpage di dalamnya.

Tujuannya:
- membuat struktur `Settings` lebih jelas
- menghindari tabrakan fungsi antar item
- menyederhanakan UX untuk user warung usia 45+
- memastikan setiap item settings punya arah yang jelas

---

## 2. UX Direction

### Prinsip utama
- `Settings` adalah pusat utilitas, bukan dashboard
- item harus mudah dipahami dalam sekali lihat
- hindari duplikasi aksi
- tiap page fokus ke satu tujuan
- form sesingkat mungkin

### Keputusan UX penting
- card ringkasan di halaman `Settings` hanya menampilkan info singkat user + warung
- **tidak ada tombol `Edit Profil` di card atas**
- item `Profil Saya` membuka halaman detail profil
- aksi edit dilakukan dari halaman detail terkait
- email **tidak dipakai**
- data inti yang dipakai hanya:
  - nama pemilik
  - nomor telepon
  - nama warung
  - alamat warung

---

## 3. Information Architecture

Struktur yang direkomendasikan:

1. `Settings`
2. `Profil Saya`
3. `Edit Profil`
4. `Data Warung`
5. `Edit Data Warung`
6. `Ubah Password`
7. `Periode Default`
8. `Notifikasi`
9. `Bahasa`
10. `Kategori Produk`
11. `Kategori Pengeluaran`
12. `Satuan Produk`
13. `Saldo Awal`
14. `Pusat Bantuan`
15. `Tentang Aplikasi`
16. `Kebijakan Privasi`
17. `Logout Confirmation`

---

## 4. Main Settings Page

### Purpose
- menjadi entry point ke seluruh pengaturan
- memberikan ringkasan siapa user aktif dan warung yang sedang dikelola
- mengelompokkan menu secara rapi

### Layout

```text
+------------------------------------------+
| Pengaturan                               |
+------------------------------------------+
| +--------------------------------------+ |
| | F  Fachri                            | |
| |    Warung Berkah                     | |
| |    6282xxxxxxxx                      | |
| +--------------------------------------+ |
|                                          |
| AKUN                                     |
| +--------------------------------------+ |
| | Profil Saya                        > | |
| | Lihat info profil pemilik            | |
| +--------------------------------------+ |
| | Data Warung                        > | |
| | Kelola nama dan alamat warung        | |
| +--------------------------------------+ |
| | Ubah Password                      > | |
| | Ganti kata sandi akun               | |
| +--------------------------------------+ |
|                                          |
| PREFERENSI                               |
| +--------------------------------------+ |
| | Periode Default                   > | |
| | Atur periode awal laporan           | |
| +--------------------------------------+ |
| | Notifikasi                        > | |
| | Atur pengingat dan alert            | |
| +--------------------------------------+ |
| | Bahasa                            > | |
| | Ganti bahasa aplikasi               | |
| +--------------------------------------+ |
|                                          |
| DATA & WARUNG                            |
| +--------------------------------------+ |
| | Kategori Produk                   > | |
| | Kelola pengelompokan produk         | |
| +--------------------------------------+ |
| | Kategori Pengeluaran              > | |
| | Atur jenis pengeluaran warung       | |
| +--------------------------------------+ |
| | Satuan Produk                     > | |
| | Kelola satuan barang               | |
| +--------------------------------------+ |
| | Saldo Awal                        > | |
| | Atur modal awal warung             | |
| +--------------------------------------+ |
|                                          |
| BANTUAN & INFO                           |
| +--------------------------------------+ |
| | Pusat Bantuan                     > | |
| | Panduan penggunaan aplikasi         | |
| +--------------------------------------+ |
| | Tentang Aplikasi                  > | |
| | Informasi CatatCuan                 | |
| +--------------------------------------+ |
| | Kebijakan Privasi                 > | |
| | Penjelasan data dan keamanan        | |
| +--------------------------------------+ |
|                                          |
| DANGER ZONE                              |
| +--------------------------------------+ |
| | Keluar Aplikasi                      | |
| +--------------------------------------+ |
+------------------------------------------+
```

### Rules
- card atas hanya ringkasan, bukan action center
- section title harus jelas
- item menu pakai icon + title + subtitle + chevron
- `Danger Zone` dipisah dan merah

---

## 5. Profil Saya

### Purpose
- menampilkan detail profil pemilik akun
- menjadi halaman baca dulu, edit kemudian

### Contents
- nama pemilik
- nomor telepon

### Layout

```text
+------------------------------------------+
| Profil Saya                        [Edit]|
+------------------------------------------+
|                                          |
| +--------------------------------------+ |
| |        [ Avatar / Inisial ]          | |
| |        Fachri                        | |
| |        Pemilik Warung                | |
| +--------------------------------------+ |
|                                          |
| INFORMASI PEMILIK                        |
| +--------------------------------------+ |
| | Nama Pemilik                         | |
| | Fachri                               | |
| |--------------------------------------| |
| | Nomor Telepon                        | |
| | 6282xxxxxxxx                         | |
| +--------------------------------------+ |
+------------------------------------------+
```

### UX Notes
- tombol `Edit` ada di app bar atau kanan atas card
- tampil bersih, tidak perlu banyak field
- jangan tampilkan email

---

## 6. Edit Profil

### Purpose
- mengubah data pemilik akun

### Fields
- nama pemilik
- nomor telepon

### Layout

```text
+------------------------------------------+
| Edit Profil                              |
+------------------------------------------+
|                                          |
| NAMA PEMILIK                             |
| +--------------------------------------+ |
| | Fachri                               | |
| +--------------------------------------+ |
|                                          |
| NOMOR TELEPON                            |
| +--------------------------------------+ |
| | 6282xxxxxxxx                         | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | Simpan Perubahan                     | |
| +--------------------------------------+ |
+------------------------------------------+
```

### Rules
- field sedikit dan jelas
- tombol simpan penuh lebar
- validasi sederhana
- nomor telepon gunakan keyboard numerik / telepon

---

## 7. Data Warung

### Purpose
- menampilkan identitas warung secara terpisah dari profil pemilik

### Contents
- nama warung
- alamat warung
- saldo awal ringkas jika perlu

### Layout

```text
+------------------------------------------+
| Data Warung                        [Edit]|
+------------------------------------------+
|                                          |
| +--------------------------------------+ |
| | Nama Warung                          | |
| | Warung Berkah                        | |
| |--------------------------------------| |
| | Alamat Warung                        | |
| | Jl. Melati No. 10                    | |
| |--------------------------------------| |
| | Saldo Awal                           | |
| | Rp 1.000.000                         | |
| +--------------------------------------+ |
+------------------------------------------+
```

### UX Notes
- ini read-only detail page
- edit dilakukan lewat tombol `Edit`

---

## 8. Edit Data Warung

### Purpose
- mengubah identitas warung

### Fields
- nama warung
- alamat warung

### Layout

```text
+------------------------------------------+
| Edit Data Warung                         |
+------------------------------------------+
|                                          |
| NAMA WARUNG                              |
| +--------------------------------------+ |
| | Warung Berkah                        | |
| +--------------------------------------+ |
|                                          |
| ALAMAT WARUNG                            |
| +--------------------------------------+ |
| | Jl. Melati No. 10                    | |
| |                                      | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | Simpan Perubahan                     | |
| +--------------------------------------+ |
+------------------------------------------+
```

### Rules
- jangan campur dengan data pemilik
- alamat boleh multiline
- form tetap singkat

---

## 9. Ubah Password

### Purpose
- mengganti kata sandi akun dengan aman

### Fields
- password lama
- password baru
- konfirmasi password baru

### Layout

```text
+------------------------------------------+
| Ubah Password                            |
+------------------------------------------+
|                                          |
| PASSWORD LAMA                            |
| +--------------------------------------+ |
| | ************                         | |
| +--------------------------------------+ |
|                                          |
| PASSWORD BARU                            |
| +--------------------------------------+ |
| | ************                         | |
| +--------------------------------------+ |
|                                          |
| KONFIRMASI PASSWORD BARU                 |
| +--------------------------------------+ |
| | ************                         | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | Simpan Password                      | |
| +--------------------------------------+ |
+------------------------------------------+
```

### UX Notes
- sediakan show/hide password
- error tampil dekat field
- gunakan bahasa sederhana

---

## 10. Periode Default

### Purpose
- menentukan periode awal yang dipakai saat user membuka halaman `Laporan` atau `Stats`

### Recommended interaction
- page sederhana atau bottom sheet

### Options
- Harian
- Mingguan
- Bulanan
- Triwulanan

### Layout

```text
+------------------------------------------+
| Periode Default                          |
+------------------------------------------+
|                                          |
| Pilih periode yang ingin ditampilkan     |
| pertama kali saat membuka laporan.       |
|                                          |
| ( ) Harian                               |
| ( ) Mingguan                             |
| (o) Bulanan                              |
| ( ) Triwulanan                           |
|                                          |
| +--------------------------------------+ |
| | Simpan                                | |
| +--------------------------------------+ |
+------------------------------------------+
```

---

## 11. Notifikasi

### Purpose
- memberi kontrol sederhana terhadap pengingat penting

### Recommended scope
- pengingat hutang jatuh tempo
- alert stok menipis
- reminder pencatatan harian

### Layout

```text
+------------------------------------------+
| Notifikasi                               |
+------------------------------------------+
| +--------------------------------------+ |
| | Pengingat Hutang Jatuh Tempo    [ON] | |
| | Ingatkan jika ada tagihan mendekat    | |
| +--------------------------------------+ |
| | Alert Stok Menipis              [ON] | |
| | Beri tahu saat stok hampir habis      | |
| +--------------------------------------+ |
| | Reminder Catat Harian           [OFF]| |
| | Ingatkan untuk cek pencatatan         | |
| +--------------------------------------+ |
+------------------------------------------+
```

### Rules
- pakai switch, bukan menu berlapis
- jangan terlalu banyak opsi di V1

---

## 12. Bahasa

### Purpose
- memilih bahasa tampilan aplikasi

### Recommended V1
- Bahasa Indonesia
- placeholder untuk bahasa lain jika belum siap

### Layout

```text
+------------------------------------------+
| Bahasa                                   |
+------------------------------------------+
|                                          |
| (o) Bahasa Indonesia                     |
| ( ) English                              |
|                                          |
| +--------------------------------------+ |
| | Simpan                                | |
| +--------------------------------------+ |
+------------------------------------------+
```

### Note
- kalau `English` belum siap, bisa ditandai `Segera hadir`

---

## 13. Kategori Produk

### Purpose
- mengelola daftar kategori produk warung

### Layout

```text
+------------------------------------------+
| Kategori Produk                    [+]   |
+------------------------------------------+
| +--------------------------------------+ |
| | Makanan Ringan                    [..]| |
| +--------------------------------------+ |
| | Minuman                           [..]| |
| +--------------------------------------+ |
| | Sembako                           [..]| |
| +--------------------------------------+ |
+------------------------------------------+
```

### Actions
- tambah kategori
- edit kategori
- hapus kategori jika aman

---

## 14. Kategori Pengeluaran

### Purpose
- mengelola jenis pengeluaran warung

### Layout

```text
+------------------------------------------+
| Kategori Pengeluaran               [+]   |
+------------------------------------------+
| +--------------------------------------+ |
| | Belanja Stok                      [..]| |
| +--------------------------------------+ |
| | Listrik                           [..]| |
| +--------------------------------------+ |
| | Transport                         [..]| |
| +--------------------------------------+ |
+------------------------------------------+
```

### Notes
- bisa dibedakan internal jika ada tipe operasional
- UI tetap sederhana untuk user

---

## 15. Satuan Produk

### Purpose
- mengelola satuan barang

### Layout

```text
+------------------------------------------+
| Satuan Produk                      [+]   |
+------------------------------------------+
| +--------------------------------------+ |
| | Pcs                               [..]| |
| +--------------------------------------+ |
| | Kg                                [..]| |
| +--------------------------------------+ |
| | Botol                             [..]| |
| +--------------------------------------+ |
+------------------------------------------+
```

---

## 16. Saldo Awal

### Purpose
- mengatur modal awal warung secara jelas

### Recommended scope
- saldo awal uang laci
- saldo awal kas warung bila memang dipakai

### Layout

```text
+------------------------------------------+
| Saldo Awal                               |
+------------------------------------------+
|                                          |
| UANG LACI AWAL                           |
| +--------------------------------------+ |
| | Rp 1.000.000                         | |
| +--------------------------------------+ |
|                                          |
| UANG KAS AWAL                            |
| +--------------------------------------+ |
| | Rp 500.000                           | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | Simpan Saldo Awal                    | |
| +--------------------------------------+ |
+------------------------------------------+
```

### Rule
- kalau hanya satu saldo yang benar-benar dipakai sistem, tampilkan satu saja
- jangan memunculkan istilah yang bikin bingung user

---

## 17. Pusat Bantuan

### Purpose
- membantu user memahami cara pakai aplikasi

### Recommended V1
- FAQ sederhana
- langkah penggunaan dasar

### Layout

```text
+------------------------------------------+
| Pusat Bantuan                            |
+------------------------------------------+
| +--------------------------------------+ |
| | Cara mencatat penjualan           >  | |
| +--------------------------------------+ |
| | Cara mencatat pengeluaran         >  | |
| +--------------------------------------+ |
| | Cara melihat laporan              >  | |
| +--------------------------------------+ |
| | Cara mengelola hutang             >  | |
| +--------------------------------------+ |
+------------------------------------------+
```

---

## 18. Tentang Aplikasi

### Purpose
- menampilkan identitas singkat aplikasi

### Layout

```text
+------------------------------------------+
| Tentang Aplikasi                         |
+------------------------------------------+
|                                          |
| CatatCuan                                |
| Aplikasi pencatatan warung sederhana     |
|                                          |
| Versi Aplikasi                           |
| 1.0.0                                    |
|                                          |
| Dibuat untuk membantu pemilik warung     |
| mencatat usaha tanpa buku manual.        |
+------------------------------------------+
```

---

## 19. Kebijakan Privasi

### Purpose
- menjelaskan penggunaan data secara sederhana

### Layout

```text
+------------------------------------------+
| Kebijakan Privasi                        |
+------------------------------------------+
|                                          |
| CatatCuan menyimpan data akun dan        |
| data warung untuk membantu pencatatan    |
| usaha.                                   |
|                                          |
| Data tidak dibagikan tanpa izin.         |
|                                          |
| +--------------------------------------+ |
| | Saya Mengerti                         | |
| +--------------------------------------+ |
+------------------------------------------+
```

### UX Notes
- gunakan bahasa pendek, bukan paragraf hukum panjang
- kalau perlu versi lengkap, sediakan scroll

---

## 20. Logout Confirmation

### Purpose
- memastikan aksi sensitif tidak dilakukan tanpa sengaja

### Layout

```text
+------------------------------------------+
|              Konfirmasi                  |
|------------------------------------------|
| Apakah kamu yakin ingin keluar           |
| dari aplikasi?                           |
|                                          |
|        [ Batal ]      [ Keluar ]         |
+------------------------------------------+
```

### Rules
- `Batal` netral
- `Keluar` merah
- dialog singkat dan jelas

---

## 21. State Recommendations

### Loading state
- profile summary pakai skeleton ringan
- list item tidak perlu semua loading kompleks

### Empty state
- jika data profil belum lengkap:

```text
+------------------------------------------+
| Profil belum lengkap                     |
| Lengkapi nama pemilik dan data warung    |
| agar pengaturan lebih mudah dipakai.     |
| [ Lengkapi Sekarang ]                    |
+------------------------------------------+
```

### Error state
- gunakan pesan sederhana
- beri tombol `Coba Lagi` bila perlu

---

## 22. Final Recommendation

Struktur terbaik untuk CatatCuan saat ini:
- `Settings` tetap jadi hub menu
- `Profil Saya` dan `Data Warung` dipisah jelas
- aksi edit ada di halaman detail masing-masing
- tidak ada email
- tidak ada duplikasi fungsi `Edit Profil` di card utama settings

Dengan struktur ini, `Settings` akan terasa:
- lebih rapi
- lebih mudah dipahami
- cocok untuk user warung
- tidak membingungkan user usia 45+
