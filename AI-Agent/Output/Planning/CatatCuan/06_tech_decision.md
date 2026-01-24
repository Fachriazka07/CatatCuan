# CatatCuan - Tech Stack Decision

**Date:** 2026-01-20
**Type:** Finance App (UMKM Cash Flow)
**Tier:** Tier 2 (Business - with sync & admin dashboard)
**Decision:** ✅ **APPROVED**

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CATATCUAN ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐         ┌──────────────────┐                      │
│  │   MOBILE APP     │         │  ADMIN DASHBOARD │                      │
│  │   (Flutter)      │         │   (Next.js)      │                      │
│  │                  │         │                  │                      │
│  │  ┌────────────┐  │         │  - User Mgmt     │                      │
│  │  │  SQLite    │  │  Sync   │  - Analytics     │                      │
│  │  │  (Drift)   │◄─┼────────►│  - Backup Status │                      │
│  │  └────────────┘  │         │  - Maintenance   │                      │
│  │       ▲          │         │  - Broadcast Msg │                      │
│  │       │          │         └────────┬─────────┘                      │
│  │       ▼          │                  │                                │
│  │  PowerSync SDK   │                  │                                │
│  └────────┬─────────┘                  │                                │
│           │                            │                                │
│           │                            │                                │
│           ▼                            ▼                                │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │                      SUPABASE (Backend)                       │      │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │      │
│  │  │  PostgreSQL  │  │     Auth     │  │   Storage    │        │      │
│  │  │  (Database)  │  │  (GoTrue)    │  │   (Backup)   │        │      │
│  │  └──────────────┘  └──────────────┘  └──────────────┘        │      │
│  │  ┌──────────────┐  ┌──────────────┐                          │      │
│  │  │ Edge Func    │  │  Realtime    │                          │      │
│  │  │ (Deno/API)   │  │ (WebSocket)  │                          │      │
│  │  └──────────────┘  └──────────────┘                          │      │
│  └──────────────────────────────────────────────────────────────┘      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Final Stack Decision

| Layer | Technology | Version | Rationale |
|-------|------------|---------|-----------|
| **Mobile** | Flutter | 3.24+ | User preference, cross-platform, great offline support |
| **Mobile DB** | Drift (SQLite) | 2.x | Type-safe, reactive, best for offline-first |
| **Sync Layer** | PowerSync | Latest | Automatic two-way sync with Supabase |
| **Backend** | Supabase | - | PostgreSQL + Auth + Storage + Realtime bundled |
| **Admin Dashboard** | Next.js 14 | 14.x | Full-stack React, SSR, API routes built-in |
| **UI Framework (Admin)** | Tailwind CSS + shadcn/ui | - | Fast development, professional look |
| **Hosting (Admin)** | Vercel | - | Free tier, integrated with Next.js |
| **Auth** | Supabase Auth | - | Built-in, supports email/password |

---

## 📱 Mobile Tech Stack (Flutter)

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | 3.24+ | Framework |
| `drift` | ^2.18 | Local SQLite database (type-safe) |
| `powersync` | Latest | Offline-first sync with Supabase |
| `supabase_flutter` | ^2.5 | Supabase SDK |
| `connectivity_plus` | ^6.0 | Network status detection |
| `workmanager` | ^0.5 | Background sync |

### UI & State Management

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.5 | State management |
| `go_router` | ^14.0 | Navigation |
| `flutter_local_notifications` | ^17.0 | Push notifications |
| `share_plus` | ^9.0 | Export/share reports |
| `excel` | ^3.0 | Excel export |
| `intl` | ^0.19 | Date/currency formatting |

### Evaluation: Flutter vs React Native

| Criteria | Flutter | React Native | Weight |
|----------|---------|--------------|--------|
| Performance | 5/5 (native compile) | 4/5 (JS bridge) | High |
| Offline Support | 5/5 (Drift excellent) | 4/5 (SQLite wrappers) | High |
| Developer Familiarity | 4/5 (Dart learning) | 3/5 (not familiar) | High |
| UI Consistency | 5/5 (same on all devices) | 3/5 (platform-specific) | Medium |
| Community | 4/5 | 5/5 | Medium |
| **TOTAL** | **23/25** | **19/25** | |

**Winner:** Flutter — Better performance, excellent offline-first tooling (Drift + PowerSync), user preference.

---

## 🖥️ Admin Dashboard Tech Stack (Web)

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `next` | 14.x | Full-stack React framework |
| `react` | 18.x | UI library |
| `typescript` | 5.x | Type safety |
| `@supabase/supabase-js` | ^2.45 | Supabase client |
| `@tanstack/react-query` | ^5.0 | Server state management |
| `tailwindcss` | ^3.4 | Utility-first CSS |
| `recharts` | ^2.12 | Charts for analytics |
| `shadcn/ui` | Latest | UI component library |

### Evaluation: Next.js vs Nuxt vs Vue

| Criteria | Next.js | Nuxt 3 | Plain Vue | Weight |
|----------|---------|--------|-----------|--------|
| Full-Stack Capability | 5/5 | 4/5 | 2/5 | High |
| Supabase Integration | 5/5 | 4/5 | 4/5 | High |
| Learning Curve | 4/5 | 4/5 | 5/5 | Medium |
| Admin Templates | 5/5 | 4/5 | 4/5 | Medium |
| TypeScript Support | 5/5 | 4/5 | 4/5 | Medium |
| **TOTAL** | **24/25** | **20/25** | **19/25** | |

**Winner:** Next.js — Best full-stack solution, excellent Supabase integration, many admin templates available.

---

## 🗄️ Backend: Supabase

### Why Supabase?

| Feature | Benefit |
|---------|---------|
| **PostgreSQL** | Production-grade database, Row Level Security (RLS) |
| **Built-in Auth** | Email/password, no need for custom auth |
| **Realtime** | WebSocket for live updates |
| **Storage** | File backup for user data |
| **Edge Functions** | Serverless API for custom logic |
| **Free Tier** | 500MB database, 1GB storage, 2GB bandwidth |

### Database Schema (Preview)

```sql
-- Users table (managed by Supabase Auth)
-- Additional user metadata
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  store_name TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_sync TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE
);

-- Transactions table (synced from mobile)
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  type TEXT CHECK (type IN ('income', 'expense', 'personal')),
  amount DECIMAL(12,2),
  note TEXT,
  transaction_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ
);

-- App settings (maintenance mode, etc.)
CREATE TABLE app_settings (
  id TEXT PRIMARY KEY,
  value JSONB,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 🔄 Sync Strategy: PowerSync

### Why PowerSync?

| Feature | Benefit |
|---------|---------|
| **Automatic Sync** | No manual sync code needed |
| **Conflict Resolution** | Built-in last-write-wins or custom |
| **Offline-First** | Full functionality without internet |
| **Supabase Native** | Official integration |

### Sync Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        SYNC FLOW                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐                        ┌─────────────┐         │
│  │   Mobile    │                        │  Supabase   │         │
│  │   (Drift)   │                        │ (PostgreSQL)│         │
│  └──────┬──────┘                        └──────┬──────┘         │
│         │                                      │                │
│         │  1. User adds transaction            │                │
│         │  ─────────────────────────►          │                │
│         │  (saved to local SQLite)             │                │
│         │                                      │                │
│         │  2. PowerSync queues change          │                │
│         │  ─────────────────────────►          │                │
│         │                                      │                │
│         │  3. When online, sync uploads        │                │
│         │  ─────────────────────────►          │                │
│         │                                      │                │
│         │  4. Server-side changes sync back    │                │
│         │  ◄─────────────────────────          │                │
│         │                                      │                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛡️ Security Considerations

| Aspect | Implementation |
|--------|----------------|
| **Authentication** | Supabase Auth (email/password) |
| **Authorization** | Row Level Security (RLS) on PostgreSQL |
| **Data Encryption** | HTTPS for transit, encrypted at rest |
| **API Security** | Supabase API keys, RLS policies |
| **Admin Access** | Separate admin role in Supabase |

---

## 💰 Cost Analysis

### Free Tier Limits (Supabase)

| Resource | Free Limit | Expected Usage | Status |
|----------|------------|----------------|--------|
| Database | 500 MB | ~50-100 MB (MVP) | ✅ OK |
| Storage | 1 GB | ~200 MB (backups) | ✅ OK |
| Bandwidth | 2 GB/month | ~500 MB/month | ✅ OK |
| Edge Functions | 50K invocations | ~10K/month | ✅ OK |

### Paid Tier (If Needed)

| Plan | Cost | When Needed |
|------|------|-------------|
| Pro | $25/month | >500 users active |
| Team | $599/month | Enterprise features |

**Projection:** Free tier sufficient for first 6-12 months.

---

## 📋 Updated Feature List (With Sync)

### Phase 1 (MVP) — 6-8 minggu (updated)

| # | Feature | Platform | Sync |
|---|---------|----------|------|
| 1 | Catat Transaksi | Mobile | ✅ Yes |
| 2 | Dashboard "Untung Hari Ini" | Mobile | Local |
| 3 | Laporan Harian/Mingguan/Bulanan | Mobile | Local |
| 4 | Export Excel | Mobile | Local |
| 5 | Offline Mode | Mobile | Auto-sync |
| 6 | User Auth (Login/Register) | Both | ✅ Yes |
| 7 | Admin: User Management | Web | ✅ Yes |
| 8 | Admin: Maintenance Mode | Web | ✅ Yes |

### Phase 1.5 — 3-4 minggu

| # | Feature | Platform | Sync |
|---|---------|----------|------|
| 9 | Admin: Analytics Dashboard | Web | ✅ Yes |
| 10 | Admin: Backup Status | Web | ✅ Yes |
| 11 | Fitur Hutang | Mobile | ✅ Yes |
| 12 | Admin: Broadcast Message | Web | ✅ Yes |

---

## ⚠️ Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| PowerSync learning curve | Medium | Medium | Follow official tutorials, start simple |
| Supabase free tier limits | Low | Medium | Monitor usage, optimize queries |
| Sync conflicts | Low | Medium | Use last-write-wins for MVP |
| Admin dashboard scope creep | Medium | High | Strict MVP scope: 4 modules only |

---

## 🔄 Next Steps

| # | Action | Est. Time |
|---|--------|-----------|
| 1 | Create Project Charter with updated scope | 1 day |
| 2 | Setup Flutter project with Drift + PowerSync | 2-3 days |
| 3 | Setup Supabase project with schema | 1 day |
| 4 | Setup Next.js admin dashboard skeleton | 1-2 days |
| 5 | Begin mobile development (Phase 1 features) | 4-5 weeks |

---

## ✅ Tech Stack Checklist

- [x] Application type identified (Finance/UMKM)
- [x] Tier determined (Tier 2 - Business)
- [x] Research conducted
- [x] Mobile stack evaluated (Flutter wins)
- [x] Admin stack evaluated (Next.js wins)
- [x] Backend selected (Supabase)
- [x] Sync strategy defined (PowerSync)
- [x] Security considerations documented
- [x] Cost analysis done
- [x] Timeline impact assessed (+2 weeks for admin)

---

*Generated by Tech Stack Evaluation Workflow (WF-P07)*
*Date: 2026-01-20*
