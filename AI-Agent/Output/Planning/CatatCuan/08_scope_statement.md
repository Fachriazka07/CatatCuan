# CatatCuan - Scope Statement

**Project ID:** PRJ-20260120-001
**Version:** 1.0
**Date:** 2026-01-20
**Phase:** 01 (MVP)

---

## 📋 Project Description

**CatatCuan** adalah aplikasi mobile "Asisten Keuangan Digital" untuk pemilik Toko Kelontong Tradisional yang menyediakan:
- Pencatatan arus kas sederhana (masuk/keluar/pribadi)
- Dashboard profit harian dengan "Bocor Alus" tracker
- Laporan keuangan exportable

**Target Users:** Pemilik Warung/Toko Kelontong Tradisional di Indonesia
**Timeline:** 8 minggu (20 Jan - 15 Mar 2026)
**Deliverable:** Android App + Admin Dashboard Web

---

## ✅ IN SCOPE

### 🔴 Core Features (Must Have) - 7 Fitur Utama

| # | Feature | Sub-Features | Platform | Priority |
|---|---------|--------------|----------|----------|
| 1 | **🛒 Transaksi Penjualan (POS)** | Scan Barcode, Keranjang Belanja, Quick Cash (50rb/100rb), Kalkulator Kembalian, Struk Digital | Mobile | 🔴 Must |
| 2 | **📦 Manajemen Produk & Stok** | Input Nama/Kategori/Harga Modal/Harga Jual, Analisis Margin, Alert Stok Rendah | Mobile | 🔴 Must |
| 3 | **💸 Pencatatan Pengeluaran** | Kategori (Listrik, Gaji, Sewa, dll), Upload Bukti Struk, Auto-potong Saldo Kas | Mobile | 🔴 Must |
| 4 | **📖 Buku Kas (Digital Ledger)** | Mutasi Real-time (+/-), Running Balance, Saldo Awal | Mobile | 🔴 Must |
| 5 | **🤝 Manajemen Hutang (Piutang)** | Daftar Penghutang, Jatuh Tempo, Pembayaran Cicilan | Mobile | 🔴 Must |
| 6 | **👥 Database Pelanggan** | Profil (Nama, Phone, Alamat), Riwayat Belanja | Mobile | 🔴 Must |
| 7 | **📊 Laporan Keuangan** | Laba/Rugi, Produk Terlaris, Export Excel/PDF | Mobile | 🔴 Must |
| 8 | **Offline Mode + Auto Sync** | Semua fitur bekerja tanpa internet, PowerSync | Mobile | 🔴 Must |
| 9 | **📈 Admin: Dashboard Statistik** | Total User, Volume Transaksi Global, Grafik Pertumbuhan | Web | 🔴 Must |
| 10 | **👤 Admin: Manajemen Pengguna** | Daftar Warung, Aktivasi/Suspend Akun, Reset Password | Web | 🔴 Must |
| 11 | **🔧 Admin: Maintenance System** | Toggle Maintenance Mode, Force Update, Backup DB, Cleanup Data | Web | 🔴 Must |
| 12 | **📋 Admin: Master Data Template** | Kelola Kategori Produk Default | Web | 🔴 Must |

### 🟡 Should Have Features

| # | Feature | Description | Platform | Priority |
|---|---------|-------------|----------|----------|
| 9 | **Export Excel** | Download laporan dalam format .xlsx | Mobile | 🟡 Should |
| 10 | **Edit/Delete Transaction** | Koreksi atau hapus transaksi yang salah input | Mobile | 🟡 Should |
| 11 | **Simple Onboarding** | 3-slide tutorial saat pertama kali buka app | Mobile | 🟡 Should |

### 📦 Platforms

| Platform | Technology | Scope |
|----------|------------|-------|
| ✅ **Android** | Flutter 3.24+ | Primary target, Play Store |
| ✅ **Web (Admin)** | Next.js 14 | Admin dashboard only |
| ❌ iOS | - | Out of Scope (Phase 2) |
| ❌ Desktop | - | Out of Scope |

### 🔗 Integrations

| Integration | Purpose | Status |
|-------------|---------|--------|
| ✅ **Supabase Auth** | User authentication | Required |
| ✅ **Supabase Database** | Cloud PostgreSQL | Required |
| ✅ **PowerSync** | Offline-first sync | Required |
| ✅ **Excel Library** | Export reports | Required |
| ❌ Payment Gateway | Subscription | Out of Scope |
| ❌ SMS/WhatsApp | Notifications | Out of Scope |

### 📄 Deliverables

| # | Deliverable | Format | Owner |
|---|-------------|--------|-------|
| 1 | **Source Code (Mobile)** | Flutter project (GitHub) | Fachri |
| 2 | **Source Code (Admin)** | Next.js project (GitHub) | Fachri |
| 3 | **APK File** | Android Package | Fachri |
| 4 | **Play Store Listing** | Published app | Fachri |
| 5 | **Admin Dashboard URL** | Deployed on Vercel | Fachri |
| 6 | **User Documentation** | In-app FAQ + PDF | Fachri |
| 7 | **Database Schema** | Supabase PostgreSQL | Fachri |

### 🎓 Support & Warranty

| Item | Scope |
|------|-------|
| Bug Fixes | 30 hari setelah launch |
| Feature Updates | Phase 1.5 (setelah MVP) |
| User Support | WhatsApp group untuk beta testers |
| Maintenance | Scheduled via Admin Dashboard |

---

## ❌ OUT OF SCOPE (Phase 01)

> ⚠️ **RULE-P05:** Minimum 3 Out of Scope items - ✅ We have 10+

### Phase 1.5 (After MVP - 3-4 weeks)

| # | Feature | Reason | Est. Effort |
|---|---------|--------|-------------|
| 1 | **Backup/Restore Manual** | Export/import data untuk pindah HP | 3 days |
| 2 | **Admin Analytics** | Grafik: total user, total omzet global | 1 week |
| 3 | **Admin Broadcast** | Kirim pesan ke semua user | 2 days |

### Phase 2 (After Validation - 4-6 weeks)

| # | Feature | Reason | Est. Effort |
|---|---------|--------|-------------|
| 6 | **Reminder/Notification** | Tagih hutang otomatis, stock alert | 1 week |
| 7 | **Multi-language** | English, regional languages | 1 week |
| 8 | **iOS Version** | Apple App Store | 2 weeks |
| 9 | **Payment Integration** | Subscription via Midtrans/Stripe | 2 weeks |
| 10 | **Full Inventory** | Complete stock management system | 3 weeks |
| 11 | **Advanced Reports** | Charts, graphs, trends | 1 week |
| 12 | **Multi-Store** | Manage multiple warung locations | 2 weeks |
| 13 | **POS Mode** | Per-item transaction scanning | 3 weeks |
| 14 | **Cloud Backup Scheduler** | Automatic daily backup | 3 days |

### Explicitly NOT Building

| Item | Reason |
|------|--------|
| ❌ Accounting Software | We are NOT an accounting app, fokus cash flow saja |
| ❌ Full POS System | User tidak mau input barang satu-satu |
| ❌ E-commerce | Tidak ada online selling feature |
| ❌ Bank Integration | Tidak ada auto-sync dengan rekening bank |
| ❌ Tax Calculation | User tidak butuh kalkulasi pajak |

---

## 📋 Assumptions

| # | Assumption | Risk if False |
|---|------------|---------------|
| 1 | Target users memiliki smartphone Android | Need iOS version (Phase 2) |
| 2 | Internet tersedia minimal 1x sehari untuk sync | Need better offline handling |
| 3 | User bersedia bayar Rp 20-50k/bulan | Adjust pricing or freemium model |
| 4 | Solo development cukup untuk 8 minggu | Need to reduce scope |
| 5 | Supabase free tier cukup untuk 500 users | Need to upgrade plan |
| 6 | User mengerti basic smartphone (WhatsApp level) | Need simpler UI |
| 7 | Flutter + PowerSync stable untuk production | Need fallback plan |

---

## 🔒 Constraints

| # | Constraint | Impact |
|---|------------|--------|
| 1 | **Solo Developer** | Limited bandwidth, sequential development |
| 2 | **Part-time Development** | ~15-20 hours/week available |
| 3 | **Budget Rp 800k** | No paid services, must use free tiers |
| 4 | **8-week Timeline** | Strict MVP scope, no feature creep |
| 5 | **Target: Low-end Devices** | Must optimize for 2GB RAM phones |
| 6 | **Offline-First Requirement** | Architecture decisions constrained |
| 7 | **Play Store Compliance** | Must follow Google policies |

---

## 🗺️ Phase Roadmap

```
┌─────────────────────────────────────────────────────────────────┐
│                    CATATCUAN PHASE ROADMAP                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Q1 2026 (Jan-Mar)                                              │
│  ┌──────────────────────────────────────────┐                   │
│  │  PHASE 01: MVP                           │                   │
│  │  • Core: Catat, Dashboard, Laporan       │                   │
│  │  • Admin: User Mgmt, Maintenance         │                   │
│  │  • Target: 50 downloads                  │                   │
│  └──────────────────────────────────────────┘                   │
│                         │                                        │
│                         ▼                                        │
│  Q2 2026 (Apr-May)                                              │
│  ┌──────────────────────────────────────────┐                   │
│  │  PHASE 1.5: Quick Wins                   │                   │
│  │  • Hutang, Stock Watchlist               │                   │
│  │  • Admin Analytics, Broadcast            │                   │
│  │  • Target: 200 downloads, 50 paid        │                   │
│  └──────────────────────────────────────────┘                   │
│                         │                                        │
│                         ▼                                        │
│  Q3-Q4 2026 (Jun-Dec)                                           │
│  ┌──────────────────────────────────────────┐                   │
│  │  PHASE 02: Scale                         │                   │
│  │  • iOS, Full Inventory, Payment          │                   │
│  │  • Reminder, Multi-store                 │                   │
│  │  • Target: 1000+ users, monetization     │                   │
│  └──────────────────────────────────────────┘                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Phase Summary

| Phase | Timeline | Scope | Success Metric |
|-------|----------|-------|----------------|
| **01 - MVP** | Jan-Mar 2026 | Core cash flow + Admin | 50 downloads |
| **1.5 - Quick Wins** | Apr-May 2026 | Hutang, Stock, Analytics | 200 downloads, 50 paid |
| **02 - Scale** | Jun-Dec 2026 | iOS, Full features | 1000+ users |

---

## ⚠️ Scope Change Process

> **RULE: No unplanned changes to MVP scope**

| Step | Action | Owner |
|------|--------|-------|
| 1 | Feature request masuk | User/Self |
| 2 | Evaluate: MVP or Phase 2? | Fachri |
| 3 | If not MVP-critical → Add to Out of Scope | Fachri |
| 4 | If MVP-critical → Trade-off dengan fitur lain | Fachri |
| 5 | Update Scope Statement & Charter | Fachri |

**Golden Rule:**
> "Jika masuk MVP, harus ada yang keluar dari MVP"

---

## ✅ Scope Checklist

- [x] Project description defined
- [x] In Scope features listed (11 items)
- [x] Out of Scope items defined (14 items - exceeds minimum 3)
- [x] Platforms specified
- [x] Integrations listed
- [x] Deliverables defined
- [x] Assumptions documented (7 items)
- [x] Constraints documented (7 items)
- [x] Phase roadmap created
- [x] Scope change process defined

---

## 🔄 Next Steps

| # | Action | Workflow | Priority |
|---|--------|----------|----------|
| 1 | Identify all risks | `/risk-register` | High |
| 2 | Compile final blueprint | `/compile-blueprint` | High |
| 3 | Start Design Phase | `/design-tier-assessment` | Next Phase |

---

*Generated by Define Scope Workflow (WF-P10)*
*Rules Applied: RULE-P05 (Scope Boundaries Defined)*
*Date: 2026-01-20*
