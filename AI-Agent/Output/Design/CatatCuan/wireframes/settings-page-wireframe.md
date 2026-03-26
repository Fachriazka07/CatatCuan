# CatatCuan - Settings Page Wireframe

**Version:** 1.0  
**Date:** 2026-03-25  
**Fidelity:** Mid-Fi (Layout + UX behavior)  
**Platform:** Mobile-First (Flutter)  
**Route:** `/setting`

---

## 1. Overview

### Purpose
Halaman `Settings` diposisikan sebagai pusat pengaturan akun, warung, preferensi aplikasi, bantuan, dan aksi sensitif seperti logout.

### Primary Goals
- Memberi user tempat yang jelas untuk mengelola akun dan warung
- Menampung pengaturan aplikasi yang tidak cocok diletakkan di halaman operasional
- Menjadi pusat akses ke bantuan, info aplikasi, dan aksi keamanan

### UX Positioning
- `Home` = ringkasan operasional
- `Laporan` = rekap dan export
- `Stats` = analitik dan trend
- `Settings` = pengaturan, preferensi, dan utilitas akun

### Product Role
Karena `Settings` ada di bottom navbar, halaman ini harus:
- mudah discan
- tidak terlalu padat
- rapi dan aman
- memisahkan aksi biasa dan aksi sensitif dengan jelas

---

## 2. Design Alignment With Existing Mobile Pages

Wireframe ini disusun agar sejalan dengan halaman mobile CatatCuan yang sudah ada:

- Header hijau seperti halaman utama lain
- Background abu muda `#F8F9FA`
- Card putih dengan border halus / shadow ringan
- Tipografi `Poppins`
- Section title uppercase atau semi-bold
- List item sederhana, mudah disentuh, dan familiar
- CTA destruktif dipisahkan jelas

### Visual Tone
- Bersih
- Aman
- Administratif ringan
- Tidak terasa seperti dashboard keuangan

---

## 3. Information Architecture

Urutan konten di halaman:

1. Header
2. Profile summary card
3. Akun
4. Preferensi
5. Data & Warung
6. Bantuan & Info
7. Danger zone

---

## 4. Main Layout Structure

```text
+------------------------------------------+
|  Pengaturan                              |
+------------------------------------------+
|                                          |
|  +------------------------------------+  |
|  | Fachri                             |  |
|  | Warung Maju Jaya                   |  |
|  | 08xxxxxxxxxx                       |  |
|  | [ Edit Profil ]                    |  |
|  +------------------------------------+  |
|                                          |
|  AKUN                                    |
|  +------------------------------------+  |
|  | Profil Saya                      > |  |
|  | Data Warung                      > |  |
|  | Ubah Password                    > |  |
|  +------------------------------------+  |
|                                          |
|  PREFERENSI                              |
|  +------------------------------------+  |
|  | Periode Default                   > |  |
|  | Notifikasi                        > |  |
|  | Bahasa                            > |  |
|  +------------------------------------+  |
|                                          |
|  DATA & WARUNG                           |
|  +------------------------------------+  |
|  | Kategori Produk                   > |  |
|  | Kategori Pengeluaran              > |  |
|  | Satuan Produk                     > |  |
|  | Saldo Awal                        > |  |
|  +------------------------------------+  |
|                                          |
|  BANTUAN & INFO                          |
|  +------------------------------------+  |
|  | Pusat Bantuan                     > |  |
|  | Tentang Aplikasi                  > |  |
|  | Kebijakan Privasi                 > |  |
|  +------------------------------------+  |
|                                          |
|  DANGER ZONE                             |
|  +------------------------------------+  |
|  | Keluar Aplikasi                    |  |
|  +------------------------------------+  |
|                                          |
+------------------------------------------+
```

---

## 5. Section Breakdown

### 5.1 Header

```text
+------------------------------------------+
|  Pengaturan                              |
+------------------------------------------+
```

**Purpose**
- Menandai halaman utilitas app
- Tetap sederhana karena ini tab bottom nav

**Behavior**
- Tidak perlu tombol close seperti modal page
- Bisa ditambah icon kecil di kanan jika nanti ada shortcut bantuan

**Style**
- Background hijau
- Teks putih
- Tinggi sekitar `96-110dp`

---

### 5.2 Profile Summary Card

```text
+--------------------------------------+
| Fachri                               |
| Warung Maju Jaya                     |
| 08xxxxxxxxxx                         |
| [ Edit Profil ]                      |
+--------------------------------------+
```

**Purpose**
- Memberi identitas cepat siapa user yang sedang login
- Menunjukkan warung aktif yang sedang dikelola

**Contents**
- Nama pemilik
- Nama warung
- Nomor telepon / akun
- Tombol `Edit Profil`

**Design Notes**
- Card putih paling atas
- Bisa diberi avatar lingkaran dengan inisial
- Tombol `Edit Profil` kecil, outline hijau

---

### 5.3 Akun Section

```text
AKUN
+--------------------------------------+
| Profil Saya                      >   |
| Data Warung                      >   |
| Ubah Password                    >   |
+--------------------------------------+
```

**Purpose**
- Menampung pengaturan yang berkaitan langsung dengan akun user dan data warung

**Recommended Items**
- `Profil Saya`
- `Data Warung`
- `Ubah Password`

**Future Optional**
- `Nomor Telepon`
- `Ganti Pemilik`

---

### 5.4 Preferensi Section

```text
PREFERENSI
+--------------------------------------+
| Periode Default                 >    |
| Notifikasi                      >    |
| Bahasa                          >    |
+--------------------------------------+
```

**Purpose**
- Menampung preferensi penggunaan aplikasi

**Recommended Items**
- `Periode Default`
  - contoh: Hari ini / Minggu ini / Bulan ini
- `Notifikasi`
  - pengingat hutang jatuh tempo
  - stok menipis
- `Bahasa`

**Future Optional**
- `Tema`
- `Format Tanggal`
- `Format Mata Uang`

---

### 5.5 Data & Warung Section

```text
DATA & WARUNG
+--------------------------------------+
| Kategori Produk                 >    |
| Kategori Pengeluaran            >    |
| Satuan Produk                   >    |
| Saldo Awal                      >    |
+--------------------------------------+
```

**Purpose**
- Menjadi pintu pengaturan master data usaha

**Recommended Items**
- `Kategori Produk`
- `Kategori Pengeluaran`
- `Satuan Produk`
- `Saldo Awal`

**Reasoning**
- Ini penting untuk operasional, tapi tidak tepat ditempatkan di `Home`
- Settings cocok sebagai pusat konfigurasi usaha

**Future Optional**
- `Backup Data`
- `Sinkronisasi`
- `Printer / Struk`

---

### 5.6 Bantuan & Info Section

```text
BANTUAN & INFO
+--------------------------------------+
| Pusat Bantuan                   >    |
| Tentang Aplikasi                >    |
| Kebijakan Privasi               >    |
+--------------------------------------+
```

**Purpose**
- Memberi akses ke bantuan, penjelasan app, dan dokumen pendukung

**Recommended Items**
- `Pusat Bantuan`
- `Tentang Aplikasi`
- `Kebijakan Privasi`

**Future Optional**
- `Syarat & Ketentuan`
- `Hubungi Admin`
- `Laporkan Bug`

---

### 5.7 Danger Zone

```text
DANGER ZONE
+--------------------------------------+
| Keluar Aplikasi                      |
+--------------------------------------+
```

**Purpose**
- Memisahkan aksi destruktif / sensitif dari pengaturan biasa

**Recommended Item**
- `Keluar Aplikasi`

**Future Optional**
- `Hapus Data Lokal`
- `Reset Onboarding`

**Important Rule**
- Aksi destruktif harus selalu pakai konfirmasi
- Warna merah hanya dipakai di area ini supaya tetap bermakna

---

## 6. Detail Item Layout Recommendation

Setiap item settings disarankan mengikuti pola sederhana:

```text
+--------------------------------------+
| [icon] Judul Item               >    |
|       Keterangan singkat             |
+--------------------------------------+
```

**Example**

```text
+--------------------------------------+
| [bell] Notifikasi               >    |
|        Atur pengingat dan alert      |
+--------------------------------------+
```

**Why**
- Lebih informatif dibanding hanya title
- User cepat paham fungsi item tanpa harus buka satu-satu

---

## 7. Modal / Dialog Recommendation

### 7.1 Logout Confirmation

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

**Behavior**
- `Batal` kembali ke settings
- `Keluar` melakukan sign out dan kembali ke welcome/login

---

### 7.2 Future Dialog - Clear Local Data

```text
+------------------------------------------+
|           Hapus Data Lokal               |
|------------------------------------------|
| Cache dan session akan dihapus           |
| dari perangkat ini. Data cloud           |
| tetap aman.                              |
|                                          |
|      [ Batal ]    [ Hapus Lokal ]        |
+------------------------------------------+
```

**Note**
- Ini belum harus ada di V1
- Tapi bagus disiapkan sebagai arah UX ke depan

---

## 8. States

### 8.1 Loading State

```text
+------------------------------------------+
|  Pengaturan                              |
+------------------------------------------+
|  +------------------------------------+  |
|  |         PROFILE SKELETON           |  |
|  +------------------------------------+  |
|                                          |
|  [ LIST SKELETON ]                       |
|  [ LIST SKELETON ]                       |
|  [ LIST SKELETON ]                       |
+------------------------------------------+
```

**When Used**
- Saat load profile summary dari cache / database

---

### 8.2 Empty / Fallback State

```text
+------------------------------------------+
|  Pengaturan                              |
+------------------------------------------+
|  +------------------------------------+  |
|  | Nama belum tersedia                |  |
|  | Data warung belum lengkap          |  |
|  | [ Lengkapi Profil ]                |  |
|  +------------------------------------+  |
+------------------------------------------+
```

**When Used**
- Jika data warung atau user belum lengkap

---

## 9. Components Breakdown

| Component | Description |
|----------|-------------|
| Header | Title `Pengaturan` |
| Profile Summary Card | Ringkasan user dan warung aktif |
| Section Title | Penanda grup pengaturan |
| Settings List Item | Item menu dengan icon, title, subtitle, chevron |
| Danger Button | Tombol logout / aksi sensitif |
| Confirmation Dialog | Konfirmasi logout atau aksi destruktif |

---

## 10. Data Mapping Recommendation

### Profile Summary
- `nama pemilik` dari data warung / user
- `nama warung`
- `nomor telepon`

### Akun
- user session
- data warung aktif

### Preferensi
- bisa disimpan lokal dulu
- contoh:
  - default period
  - notification toggle
  - language

### Data & Warung
- master kategori
- master satuan
- saldo awal

---

## 11. Interaction Flow

1. User buka tab `Setting`
2. User lihat info akun dan warung aktif
3. User pilih item pengaturan sesuai kebutuhan
4. Jika pilih item biasa, masuk ke detail page / bottom sheet
5. Jika pilih aksi sensitif, tampil dialog konfirmasi
6. Jika logout berhasil, user diarahkan ke welcome/login

---

## 12. UX Rules For This Page

- Satu layar harus cukup nyaman discan tanpa terasa berat
- Aksi sensitif harus dipisahkan dari item biasa
- Gunakan subtitle pendek agar item mudah dimengerti
- Jangan campur pengaturan akun dengan insight bisnis
- Jangan jadikan `Settings` tempat semua hal dilempar tanpa struktur
- Kelompokkan item berdasarkan mental model user

---

## 13. Future Extension

- Halaman edit profil warung
- pengaturan notifikasi jatuh tempo hutang
- printer dan template struk
- backup / restore data
- sinkronisasi offline
- pusat bantuan interaktif
- halaman versi aplikasi dan changelog

---

## 14. Implementation Notes

### Recommended V1 Scope
- Header
- Profile summary
- Akun section
- Preferensi section sederhana
- Bantuan section
- Logout confirmation

### Nice To Have V1.5
- Data & Warung section lebih lengkap
- Periode default
- Toggle notifikasi

### Explicit Non-Scope For Now
- Backup/sync kompleks
- manajemen perangkat
- tema gelap penuh
- pengaturan offline-first

Alasannya: fitur inti bisnis masih lebih penting untuk diselesaikan lebih dulu.

---

## 15. Final Direction

Halaman `Settings` CatatCuan harus terasa seperti:
- rapi
- aman
- gampang dipahami
- membantu user mengelola akun dan warung tanpa bikin bingung

Ini bukan halaman transaksi, bukan halaman analytics, dan bukan tempat semua menu dilempar.  
`Settings` harus jadi pusat utilitas yang tenang dan terpercaya.
