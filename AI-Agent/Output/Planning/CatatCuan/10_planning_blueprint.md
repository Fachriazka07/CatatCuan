# CatatCuan - Planning Blueprint

**Project ID:** PRJ-20260120-001
**Version:** 1.0
**Created:** 2026-01-20
**Planning Tier:** Tier 1 (Solo Developer)
**Status:** ✅ **Ready for Design Phase**

---

## 📋 Executive Summary

| Attribute | Value |
|-----------|-------|
| **Project** | CatatCuan - Asisten Keuangan Digital Toko Kelontong |
| **Objective** | Membantu pemilik warung tradisional mencatat arus kas dengan mudah |
| **Timeline** | 8 minggu (20 Jan - 15 Mar 2026) |
| **Budget** | Rp 800.000 |
| **Decision** | 🟢 **GO** |
| **Tech Stack** | Flutter + Supabase + Next.js |

### Key Metrics Target

| Metric | Target | Deadline |
|--------|--------|----------|
| Play Store Launch | 1 app published | 15 Mar 2026 |
| Downloads | 50 | 31 Mar 2026 |
| User Retention | 30% DAU/MAU | 30 Apr 2026 |

---

## 1. Problem & Solution

### Problem Statement

> **Pemilik Toko Kelontong Tradisional** kesulitan **mengelola arus kas** karena **catatan manual berantakan dan "bocor alus"** yang menyebabkan **modal tidak berkembang dan profit tidak jelas**.

### Top 3 Pain Points

| # | Pain Point | Urgency |
|---|------------|---------|
| 1 | **Bocor Alus** — Modal tergerus untuk keperluan pribadi tanpa tercatat | 🔴 8/10 |
| 2 | **Stok Gaib** — Barang habis baru tahu saat pelanggan bertanya | 🟡 7/10 |
| 3 | **Pusing Hitung Laba** — Tidak tahu untung bersih harian | 🟡 7/10 |

### Solution

**CatatCuan** — Aplikasi mobile sederhana untuk:
- Mencatat pemasukan, pengeluaran, dan pengambilan pribadi
- Melihat profit harian dalam 1 dashboard
- Mengenerate laporan exportable ke Excel

### Validation Status

| Stage | Status | Evidence |
|-------|--------|----------|
| Problem Validation | ✅ Passed | Pain Score 8/10, #1 priority |
| WTP Validation | ✅ Passed | Rp 20-50k/bulan acceptable |
| Market Research | ✅ Passed | 65-70M UMKM market |
| Competitor Analysis | ✅ Passed | Gap: simple cash flow vs complex POS |

**Decision:** 🟢 **GO**

---

## 2. Technical Decisions

### TELOS Score: 22/25 ✅ PROCEED

| Dimension | Score | Notes |
|-----------|-------|-------|
| Technical | 4/5 | Flutter + Supabase mature |
| Economic | 4/5 | Low cost, high ROI |
| Legal | 5/5 | No blockers |
| Operational | 5/5 | High adoption potential |
| Schedule | 4/5 | 8 weeks achievable |

### Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Mobile** | Flutter 3.24+ | Cross-platform app |
| **Mobile DB** | Drift | Type-safe SQLite |
| **Sync** | PowerSync | Offline-first sync |
| **Backend** | Supabase | PostgreSQL + Auth + Storage |
| **Admin Dashboard** | Next.js 14 | Web admin panel |
| **UI (Admin)** | Tailwind + shadcn/ui | Fast development |
| **Hosting** | Vercel | Free tier hosting |

### Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   MOBILE APP    │     │ ADMIN DASHBOARD │
│   (Flutter)     │     │   (Next.js)     │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     ▼
         ┌─────────────────────┐
         │     SUPABASE        │
         │  PostgreSQL + Auth  │
         └─────────────────────┘
```

---

## 3. Scope

### ✅ In Scope (MVP) - 7 Fitur Utama

| # | Feature | Key Sub-Features | Platform |
|---|---------|------------------|----------|
| 1 | 🛒 **Transaksi Penjualan (POS)** | Scan Barcode, Keranjang, Quick Cash, Struk Digital | Mobile |
| 2 | 📦 **Manajemen Produk & Stok** | Harga Modal/Jual, Margin, Alert Stok Rendah | Mobile |
| 3 | 💸 **Pencatatan Pengeluaran** | Kategori, Upload Bukti, Auto-potong Kas | Mobile |
| 4 | 📖 **Buku Kas (Digital Ledger)** | Mutasi Real-time, Running Balance, Saldo Awal | Mobile |
| 5 | 🤝 **Manajemen Hutang** | Daftar Penghutang, Jatuh Tempo, Cicilan | Mobile |
| 6 | 👥 **Database Pelanggan** | Profil, Riwayat Belanja | Mobile |
| 7 | 📊 **Laporan Keuangan** | Laba/Rugi, Produk Terlaris, Export Excel/PDF | Mobile |
| 8 | ⚡ **Offline Mode + Auto Sync** | PowerSync | Mobile |
| 9 | 📈 **Admin: Dashboard Statistik** | Total User, Volume Transaksi, Grafik Pertumbuhan | Web |
| 10 | 👤 **Admin: Manajemen User** | Daftar Warung, Aktivasi/Suspend, Reset Password | Web |
| 11 | 🔧 **Admin: Maintenance System** | Toggle Maintenance, Force Update, Backup DB, Cleanup | Web |
| 12 | 📋 **Admin: Master Data** | Kategori Produk Default | Web |

### ❌ Out of Scope

| Phase | Features |
|-------|----------|
| **1.5** | Backup Manual, Admin Analytics, Broadcast |
| **2** | Reminder, Multi-language, iOS, Payment, Full Inventory, Multi-Store |

### Phase Roadmap

| Phase | Timeline | Focus |
|-------|----------|-------|
| **01 - MVP** | Jan-Mar 2026 | Core cash flow + Admin |
| **1.5** | Apr-May 2026 | Hutang, Stock, Analytics |
| **02** | Jun-Dec 2026 | iOS, Full features |

---

## 4. Risks

### Summary

| Priority | Count |
|----------|-------|
| 🔴 Critical | 2 |
| 🟡 Medium | 6 |
| 🟢 Low | 4 |

### Top Risks

| ID | Risk | Score | Mitigation |
|----|------|-------|------------|
| R01 | **Scope Creep** | 9 | Strict Out of Scope list, trade-off rule |
| R12 | **Competitor Copies** | 9 | Launch fast, build loyalty |
| R02 | PowerSync Learning Curve | 6 | Follow tutorials, extra week buffer |
| R03 | Low-end Device Performance | 6 | Lightweight UI, optimize queries |
| R04 | Part-time Development | 6 | 30% buffer, prioritize ruthlessly |
| R05 | User Adoption Resistance | 6 | Extreme simplicity, onboarding |

---

## 5. Timeline

| Week | Phase | Milestone | Deliverable |
|------|-------|-----------|-------------|
| 1 | Setup | Project Setup | Flutter + Supabase + Next.js scaffold |
| 2-3 | Dev | Core Features | Transaction CRUD, Dashboard |
| 4 | Dev | Reports | Daily/Weekly/Monthly, Excel export |
| 5 | Dev | Sync | PowerSync integration |
| 6 | Dev | Admin | User management, maintenance mode |
| 7 | Test | Testing | Bug fixes, UI polish, beta test |
| 8 | Launch | Go-live | Play Store submission |

### Gantt

```
Week:  1    2    3    4    5    6    7    8
       |----|----|----|----|----|----|----|----|
Setup  ████
Mobile      ████████████████
Reports               ████
Sync                       ████
Admin                           ████
Test                                 ████
Launch                                    ████
```

---

## 6. Budget

| Category | Amount |
|----------|--------|
| Play Store | Rp 400.000 |
| Domain (optional) | Rp 150.000 |
| Beta Tester Gifts | Rp 100.000 |
| Contingency (20%) | Rp 150.000 |
| **TOTAL** | **Rp 800.000** |

### ROI Projection

| Scenario | Year 1 Revenue | ROI |
|----------|----------------|-----|
| Conservative | Rp 10.5M | +1,212% |
| Optimistic | Rp 120M | +14,900% |

---

## 7. Team (Solo)

| Role | Person | Responsibility |
|------|--------|----------------|
| Project Manager | Fachri | Planning, tracking |
| Developer | Fachri | Mobile, Admin, Backend |
| Designer | Fachri | UI/UX (using templates) |
| Tester | Fachri + Beta Users | QA, feedback |

---

## ✅ Planning Phase Handoff Checklist

| # | Item | Source | Status |
|---|------|--------|--------|
| 1 | Project Charter | `/create-charter` | ✅ Complete |
| 2 | Tech Stack Decision | `/tech-stack-eval` | ✅ Complete |
| 3 | Validated Idea | `/validate-idea` | ✅ GO Decision |
| 4 | Scope Statement | `/define-scope` | ✅ Complete |
| 5 | Risk Register | `/risk-register` | ✅ 12 risks identified |
| 6 | Feasibility Report | `/feasibility-study` | ✅ 22/25 PROCEED |
| 7 | Planning Blueprint | This document | ✅ Complete |

---

## 📎 Source Documents

| # | Document | Path |
|---|----------|------|
| 1 | Ideation Report | [01_ideation_report.md](file:///d:/Fachri/WORKSPACES/CatatCuan/AI-Agent/Output/Planning/CatatCuan/01_ideation_report.md) |
| 2 | Interview Guide | [02_interview_guide.md](file:///d:/Fachri/WORKSPACES/CatatCuan/AI-Agent/Output/Planning/CatatCuan/02_interview_guide.md) |
| 3 | Interview Notes | [03_interview_notes.md](file:///d:/Fachri/WORKSPACES/CatatCuan/AI-Agent/Output/Planning/CatatCuan/03_interview_notes.md) |
| 4 | Validation Report | [04_validation_report.md](file:///d:/Fachri/WORKSPACES/CatatCuan/AI-Agent/Output/Planning/CatatCuan/04_validation_report.md) |
| 5 | Feasibility Report | [05_feasibility_report.md](file:///d:/Fachri/WORKSPACES/CatatCuan/AI-Agent/Output/Planning/CatatCuan/05_feasibility_report.md) |
| 6 | Tech Decision | [06_tech_decision.md](file:///d:/Fachri/WORKSPACES/CatatCuan/AI-Agent/Output/Planning/CatatCuan/06_tech_decision.md) |
| 7 | Project Charter | [07_project_charter.md](file:///d:/Fachri/WORKSPACES/CatatCuan/AI-Agent/Output/Planning/CatatCuan/07_project_charter.md) |
| 8 | Scope Statement | [08_scope_statement.md](file:///d:/Fachri/WORKSPACES/CatatCuan/AI-Agent/Output/Planning/CatatCuan/08_scope_statement.md) |
| 9 | Risk Register | [09_risk_register.md](file:///d:/Fachri/WORKSPACES/CatatCuan/AI-Agent/Output/Planning/CatatCuan/09_risk_register.md) |

---

## 🚀 Next: Design Phase

### Entry Point

```
/design-tier-assessment → /choose-architecture → /design-database → /design-ui-ux
```

### Design Phase Checklist

- [ ] Run `/design-tier-assessment`
- [ ] Create System Architecture (C4 diagrams)
- [ ] Design Database Schema (ERD)
- [ ] Create UI/UX Wireframes
- [ ] Define API Contracts

---

## 🎉 Planning Phase Summary

### Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Go/No-Go** | GO | Strong validation signals |
| **Mobile Framework** | Flutter | User preference, offline support |
| **Backend** | Supabase | All-in-one, free tier |
| **Admin Dashboard** | Next.js | Full-stack React |
| **Sync Strategy** | PowerSync | Automatic offline-first |
| **MVP Scope** | 8 features | Minimal but complete |

### Planning Metrics

| Metric | Value |
|--------|-------|
| Planning Documents Created | 10 |
| Interviews Conducted | 1 + 1 follow-up |
| Risks Identified | 12 |
| In Scope Features | 11 |
| Out of Scope Features | 14 |
| Timeline | 8 weeks |
| Budget | Rp 800.000 |

---

**🎉 PLANNING PHASE COMPLETE!**

**Ready for Design Phase ✅**

---

*Generated by Compile Blueprint Workflow (WF-P13)*
*Date: 2026-01-20*
