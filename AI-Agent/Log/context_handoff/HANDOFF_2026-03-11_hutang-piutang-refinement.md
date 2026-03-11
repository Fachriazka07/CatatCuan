# Context Handoff: Hutang & Piutang UI Refinement

**Date:** 2026-03-11 07:16
**Status:** IN_PROGRESS

## 🎯 Current Objective

Menyempurnakan UI/UX dari fitur Hutang & Piutang agar senada dengan UI aplikasi secara keseluruhan, memastikan pengelompokan berdasarkan pelanggan berjalan lancar, dan menambahkan validasi nominal pembayaran.

## ✅ Completed

- [x] Mengubah `insert_hutang.dart` untuk menggunakan Customer Picker (bottom sheet dengan search).
- [x] Menyimpan data `pelanggan_id` ke dalam database saat membuat hutang baru.
- [x] Mengubah tampilan `hutang_list.dart` agar dikelompokkan berdasarkan nama pelanggan.
- [x] Mengubah desain grouped card menjadi dipisah per kotak.
- [x] Membuat list "dropdown" sub-item untuk daftar transaksi per pelanggan dengan desain border putih.
- [x] Memberikan warna hijau/kuning/merah untuk menandai nominal awal, sisa pembayaran, dan lunas.
- [x] Membedakan UI **Piutang** agar warnanya menjadi biru dan menggunakan icon panah masuk di `hutang_list.dart` (termasuk di tab LUNAS).
- [x] Menambahkan validasi agar pembayaran tidak bisa melebihi sisa tagihan di `detail_hutang.dart` beserta Snackbar error.
- [x] Mengatasi error syntax (tutup kurung bermasalah) di Flutter UI saat rewrite.

## 🔄 In Progress

- [ ] (Tidak ada task spesifik yang menggantung saat ini. UI dan validasi di hutang/piutang semua sudah diperbaiki).

## 📋 Next Steps

1. Review keseluruhan flow Hutang & Piutang oleh User (test penambahan, edit, dan list).
2. Lanjut fitur lain jika diperlukan (atau testing edge cases).

## 📁 Key Files Modified

- `d:\Fachri\WORKSPACES\CatatCuan\catatcuan-mobile\lib\features\hutang\insert_hutang.dart` - Implementasi customer picker.
- `d:\Fachri\WORKSPACES\CatatCuan\catatcuan-mobile\lib\features\hutang\hutang_list.dart` - Rewrite logika Group UI, dropdown design, warna, pembeda piutang.
- `d:\Fachri\WORKSPACES\CatatCuan\catatcuan-mobile\lib\features\hutang\detail_hutang.dart` - Tambahan logic validasi nominal pembayaran melebihi sisa.

## 🧠 Important Decisions

- Decision 1: Menggunakan desain "Opsi B" (dikumpulkan per nama kontak) agar tampilan hutang list lebih bersih walau satu kontak berhutang berkali-kali.
- Decision 2: Menggunakan warna biru/icon dropdown untuk piutang (uang masuk), dan warna hijau untuk hutang (uang keluar) agar gampang dibedakan. Desain sub-item disesuaikan agar tidak monoton.

## 💡 Context Notes

Desain dropdown sub-item di list hutang mungkin sedikit kompleks dari sisi syntax Bracket `if...else`. Jika melakukan modifikasi di file ini lagi, harap perhatikan susunan `Row` dan `Column` dan operator spread `...[]`.
