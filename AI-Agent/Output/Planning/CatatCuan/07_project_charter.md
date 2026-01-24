# CatatCuan - Project Charter

**Project ID:** PRJ-20260120-001
**Version:** 1.0
**Date Created:** 2026-01-20
**Status:** ✅ APPROVED
**Phase:** 01 (MVP)

---

## 📋 Project Information

| Field | Value |
|-------|-------|
| **Project Name** | CatatCuan - Asisten Keuangan Digital Toko Kelontong |
| **Project ID** | PRJ-20260120-001 |
| **Phase** | 01 - MVP (Minimum Viable Product) |
| **Context** | 👤 Tier 1 - Solo Developer |
| **Project Manager** | Fachri |
| **Sponsor** | Self-funded |
| **Start Date** | 20 Januari 2026 |
| **Target End Date** | 15 Maret 2026 (8 weeks) |
| **Methodology** | Kanban (flexible, no ceremony) |

---

## 🎯 Purpose & Justification

### Business Need

Pemilik Toko Kelontong Tradisional di Indonesia mengalami masalah **"Bocor Alus"** — modal usaha tergerus untuk keperluan pribadi tanpa tercatat, menyebabkan:
- Ketidaktahuan profit harian yang akurat
- Modal tidak berkembang ("toko nggak maju-maju")
- Catatan berantakan (campur belanja, hutang, pribadi)

### Market Opportunity

- **65-70 juta UMKM** di Indonesia
- **25+ juta** sudah digital (WhatsApp user)
- Aplikasi kasir existing terlalu rumit untuk warung tradisional
- Gap: Belum ada yang fokus **hanya** ke arus kas sederhana

### Strategic Alignment

- Membantu digitalisasi UMKM Indonesia
- Memberikan solusi "bridge" antara buku kas manual dan sistem digital
- Target ujikom dengan menunjukkan kemampuan full-stack development

---

## 🎯 SMART Objectives

| # | Objective | Metric | Target | Deadline | SMART Check |
|---|-----------|--------|--------|----------|-------------|
| 1 | Launch MVP di Play Store | App published | 1 app live | 15 Mar 2026 | ✅ S,M,A,R,T |
| 2 | Acquire initial users | Downloads | 50 downloads | 31 Mar 2026 | ✅ S,M,A,R,T |
| 3 | Validate product-market fit | User retention | 30% DAU/MAU | 30 Apr 2026 | ✅ S,M,A,R,T |
| 4 | Demonstrate full-stack capability | Components built | Mobile + Admin + Backend | 15 Mar 2026 | ✅ S,M,A,R,T |

### Success Criteria

- [ ] Mobile app functional with core features (Catat, Dashboard, Laporan)
- [ ] Admin dashboard operational with user management
- [ ] Data sync working between mobile and cloud
- [ ] At least 3 beta testers provide positive feedback
- [ ] Zero critical bugs at launch

---

## 📦 Scope

### ✅ In Scope (Phase 01 - MVP)

| # | Feature | Platform | Priority |
|---|---------|----------|----------|
| 1 | User Registration & Login | Both | 🔴 Must Have |
| 2 | Catat Transaksi (Masuk/Keluar/Ambil Pribadi) | Mobile | 🔴 Must Have |
| 3 | Dashboard "Untung Hari Ini" + Bocor Alus Tracker | Mobile | 🔴 Must Have |
| 4 | Laporan Harian/Mingguan/Bulanan | Mobile | 🔴 Must Have |
| 5 | Export ke Excel | Mobile | 🟡 Should Have |
| 6 | Offline Mode + Auto Sync | Mobile | 🔴 Must Have |
| 7 | Admin: User Management | Web | 🔴 Must Have |
| 8 | Admin: Maintenance Mode Toggle | Web | 🔴 Must Have |

### ❌ Out of Scope (Phase 01)

| # | Feature | Reason | Phase |
|---|---------|--------|-------|
| 1 | Fitur Hutang | Nice-to-have, complexity | Phase 1.5 |
| 2 | Backup/Restore Manual | Auto-sync sufficient for MVP | Phase 1.5 |
| 3 | Admin Analytics Dashboard | Not critical for launch | Phase 1.5 |
| 4 | Admin Broadcast Message | Can use manual notification | Phase 1.5 |
| 5 | Stock Watchlist (5-10 items) | Simple tracking for new/existing warung | Phase 1.5 |
| 6 | Reminder/Notification | Depends on user behavior data | Phase 2 |
| 7 | Multi-language Support | Focus on Indonesian first | Phase 2 |
| 8 | iOS Version | Focus on Android first (target market) | Phase 2 |
| 9 | Payment/Subscription Integration | Free for MVP | Phase 2 |
| 10 | Full Inventory Management | Complex, full feature for power users | Phase 2 |

---

## 👥 Stakeholders

| Stakeholder | Role | Interest | Influence | Communication |
|-------------|------|----------|-----------|---------------|
| **Fachri** | Developer, PM, Owner | High | High | Daily self-review |
| **Target Users** | Pemilik Warung | High | Medium | Beta testing, WhatsApp |
| **Interviewee (Ibu-ibu)** | Beta Tester | High | Medium | WhatsApp feedback |
| **Penguji Ujikom** | Evaluator | Medium | High | Final presentation |

---

## 🛠️ Tech Stack

| Layer | Technology | Version |
|-------|------------|---------|
| **Mobile** | Flutter + Drift + PowerSync | 3.24+ |
| **Backend** | Supabase (PostgreSQL + Auth) | Latest |
| **Admin Dashboard** | Next.js + Tailwind + shadcn/ui | 14.x |
| **Hosting (Admin)** | Vercel | Free tier |
| **State Management** | Riverpod | 2.5+ |
| **Sync** | PowerSync | Latest |

---

## 📅 Timeline & Milestones

| Phase | Milestone | Target Date | Duration | Owner | Deliverable |
|-------|-----------|-------------|----------|-------|-------------|
| **Week 1** | Project Setup | 27 Jan 2026 | 1 week | Fachri | Flutter + Supabase + Next.js scaffold |
| **Week 2-3** | Core Mobile Features | 10 Feb 2026 | 2 weeks | Fachri | Transaction CRUD, Dashboard |
| **Week 4** | Reports & Export | 17 Feb 2026 | 1 week | Fachri | Daily/Weekly/Monthly reports, Excel |
| **Week 5** | Sync & Offline | 24 Feb 2026 | 1 week | Fachri | PowerSync integration |
| **Week 6** | Admin Dashboard | 03 Mar 2026 | 1 week | Fachri | User management, maintenance mode |
| **Week 7** | Testing & Polish | 10 Mar 2026 | 1 week | Fachri | Bug fixes, UI polish, beta test |
| **Week 8** | Launch Prep | 15 Mar 2026 | 1 week | Fachri | Play Store submission, docs |

### Gantt Overview

```
Week:    1    2    3    4    5    6    7    8
         |----|----|----|----|----|----|----|----|
Setup    ████
Mobile        ████████████████
Reports                 ████
Sync                         ████
Admin                             ████
Testing                                ████
Launch                                      ████
```

---

## 💰 Budget

### Cost Breakdown

| Category | Item | One-time | Monthly | Notes |
|----------|------|----------|---------|-------|
| **Development** | Self | Rp 0 | - | Solo developer |
| **Infrastructure** | Play Store | Rp 400.000 | - | One-time registration |
| **Infrastructure** | Domain | Rp 150.000 | - | catatcuan.id (optional) |
| **Infrastructure** | Supabase | Rp 0 | Rp 0 | Free tier sufficient |
| **Infrastructure** | Vercel | Rp 0 | Rp 0 | Free tier sufficient |
| **Testing** | Beta Testers | Rp 100.000 | - | Small thank-you gifts |
| **Miscellaneous** | Contingency | Rp 150.000 | - | 20% buffer |
| **TOTAL** | | **Rp 800.000** | **Rp 0** | |

### ROI Projection (Year 1)

| Metric | Conservative | Optimistic |
|--------|--------------|------------|
| Users (Year 1) | 500 | 2,000 |
| Conversion to Paid | 5% | 10% |
| Paying Users | 25 | 200 |
| ARPU | Rp 35.000 | Rp 50.000 |
| Annual Revenue | Rp 10.500.000 | Rp 120.000.000 |
| **ROI** | **+1,212%** | **+14,900%** |

---

## ⚠️ Key Risks & Mitigations

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|------------|--------|------------|-------|
| 1 | **Scope creep** — Adding features mid-sprint | High | High | Strict Out of Scope list, Phase 2 bucket | Fachri |
| 2 | **PowerSync complexity** — Learning curve | Medium | Medium | Follow official tutorials, allocate extra time | Fachri |
| 3 | **Low-end device performance** — App laggy | Medium | High | Lightweight UI, optimize SQLite queries | Fachri |
| 4 | **Time constraint** — Part-time development | Medium | Medium | 30% buffer in timeline, prioritize ruthlessly | Fachri |
| 5 | **User adoption** — Target users not tech-savvy | Medium | Medium | Extreme simplicity, onboarding tutorial | Fachri |

---

## 📋 Assumptions

1. Target users (pemilik warung) have Android smartphones with WhatsApp capability
2. Internet connection available at least occasionally for sync
3. Users willing to spend 20-50k/month for useful tool
4. Solo development is sustainable for 8-week MVP timeline
5. Supabase free tier sufficient for first 500 users

---

## 🔗 Dependencies

| Dependency | Type | Status | Impact if Delayed |
|------------|------|--------|-------------------|
| Flutter SDK | External | ✅ Available | Cannot start mobile dev |
| Supabase Account | External | ✅ Available | Cannot setup backend |
| PowerSync SDK | External | ✅ Available | Cannot implement sync |
| Google Play Console | External | ⏳ Need setup | Cannot publish app |
| Vercel Account | External | ✅ Available | Cannot deploy admin |

---

## ✅ Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Project Sponsor | Self | 2026-01-20 | ✅ Approved |
| Project Manager | Fachri | 2026-01-20 | ✅ Approved |

---

## 📎 Related Documents

| Document | Path | Status |
|----------|------|--------|
| Ideation Report | `01_ideation_report.md` | ✅ Complete |
| Interview Guide | `02_interview_guide.md` | ✅ Complete |
| Interview Notes | `03_interview_notes.md` | ✅ Complete |
| Validation Report | `04_validation_report.md` | ✅ Complete |
| Feasibility Report | `05_feasibility_report.md` | ✅ Complete |
| Tech Decision | `06_tech_decision.md` | ✅ Complete |
| **Project Charter** | `07_project_charter.md` | ✅ This document |

---

## 🔄 Next Steps After Charter Approval

| # | Action | Workflow | Priority |
|---|--------|----------|----------|
| 1 | Define detailed scope | `/define-scope` | High |
| 2 | Identify all risks | `/risk-register` | High |
| 3 | Compile planning blueprint | `/compile-blueprint` | High |
| 4 | Start Design Phase | `/design-tier-assessment` | Next Phase |

---

*Generated by Project Charter Workflow (WF-P09)*
*Rules Applied: RULE-P04 (Charter Before Code), RULE-P05 (Scope Boundaries), RULE-P06 (SMART Objectives)*
*Date: 2026-01-20*
