# ADR-001: Layered Architecture untuk CatatCuan

**Status:** Accepted  
**Date:** 2026-01-22  
**Decider:** Fachri (Solo Developer)  
**Project:** CatatCuan - Asisten Keuangan Digital Toko Kelontong

---

## Context

CatatCuan adalah aplikasi mobile + web admin untuk membantu pemilik warung tradisional mencatat arus kas.

**Project Characteristics:**
- **Team:** Solo Developer
- **Timeline:** MVP (8 minggu)
- **Scale:** < 1,000 users initially
- **Tech Stack:**
  - Mobile: Flutter 3.24+ (Dart)
  - Admin Web: Next.js 14 (TypeScript)
  - Backend: Supabase (PostgreSQL + Auth + Storage)
  - Sync: PowerSync (Offline-first)

**Key Requirements:**
- Offline-first mobile app
- Simple CRUD operations
- Fast development for MVP
- Maintainable for solo developer

---

## Decision

We will use **Layered Architecture** with **Feature-First Organization** for both Flutter mobile app and Next.js admin dashboard.

### Architecture Layers

```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │
│   (UI, Widgets, Pages, State Mgmt)      │
├─────────────────────────────────────────┤
│         APPLICATION/SERVICE LAYER       │
│   (Use Cases, Business Logic)           │
├─────────────────────────────────────────┤
│         DATA LAYER                      │
│   (Repositories, Data Sources, Models)  │
└─────────────────────────────────────────┘
```

---

## Folder Structure

### Flutter Mobile App

```
lib/
├── main.dart                    # Entry point
├── app/                         # App configuration
│   ├── app.dart                 # MaterialApp setup
│   └── routes.dart              # Navigation routes
│
├── core/                        # Shared core utilities
│   ├── constants/               # App constants
│   ├── theme/                   # Design tokens, colors, typography
│   ├── utils/                   # Helper functions
│   └── widgets/                 # Shared UI components
│
├── features/                    # Feature-first organization
│   ├── auth/                    # 🔐 Authentication
│   │   ├── presentation/        # UI (screens, widgets)
│   │   ├── application/         # State management (Cubit/Bloc)
│   │   ├── data/                # Repository, data sources
│   │   └── domain/              # Models, entities
│   │
│   ├── onboarding/              # 📱 Onboarding slides
│   │   ├── presentation/
│   │   └── data/
│   │
│   ├── penjualan/               # 🛒 Transaksi Penjualan (POS)
│   │   ├── presentation/
│   │   ├── application/
│   │   ├── data/
│   │   └── domain/
│   │
│   ├── produk/                  # 📦 Manajemen Produk & Stok
│   │   ├── presentation/
│   │   ├── application/
│   │   ├── data/
│   │   └── domain/
│   │
│   ├── pengeluaran/             # 💸 Pencatatan Pengeluaran
│   │   ├── presentation/
│   │   ├── application/
│   │   └── data/
│   │
│   ├── buku_kas/                # 📖 Buku Kas (Digital Ledger)
│   │   ├── presentation/
│   │   ├── application/
│   │   └── data/
│   │
│   ├── hutang/                  # 🤝 Manajemen Hutang
│   │   ├── presentation/
│   │   ├── application/
│   │   └── data/
│   │
│   ├── pelanggan/               # 👥 Database Pelanggan
│   │   ├── presentation/
│   │   ├── application/
│   │   └── data/
│   │
│   └── laporan/                 # 📊 Laporan Keuangan
│       ├── presentation/
│       ├── application/
│       └── data/
│
├── data/                        # Shared data layer
│   ├── local/                   # Drift (SQLite) database
│   │   ├── database.dart
│   │   └── tables/
│   ├── remote/                  # Supabase client
│   │   └── supabase_client.dart
│   └── sync/                    # PowerSync integration
│       └── powersync_connector.dart
│
└── services/                    # App-level services
    ├── navigation_service.dart
    └── notification_service.dart
```

---

### Next.js Admin Dashboard

```
src/
├── app/                         # Next.js App Router
│   ├── (auth)/                  # Route group: Auth pages
│   │   ├── login/
│   │   │   └── page.tsx
│   │   └── layout.tsx
│   │
│   ├── (dashboard)/             # Route group: Dashboard pages
│   │   ├── layout.tsx           # Dashboard layout with sidebar
│   │   ├── page.tsx             # Home/Stats dashboard
│   │   ├── users/               # User management
│   │   │   ├── page.tsx
│   │   │   └── [id]/
│   │   │       └── page.tsx
│   │   ├── maintenance/         # Maintenance settings
│   │   │   └── page.tsx
│   │   └── master-data/         # Master data templates
│   │       └── page.tsx
│   │
│   ├── api/                     # API Routes (if needed)
│   │   └── health/
│   │       └── route.ts
│   │
│   ├── layout.tsx               # Root layout
│   └── globals.css
│
├── components/                  # React components
│   ├── ui/                      # shadcn/ui components
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── table.tsx
│   │   └── ...
│   ├── dashboard/               # Dashboard-specific
│   │   ├── stats-card.tsx
│   │   ├── user-table.tsx
│   │   └── sidebar.tsx
│   └── shared/                  # Shared components
│       └── header.tsx
│
├── lib/                         # Utilities & configs
│   ├── supabase/
│   │   ├── client.ts            # Browser client
│   │   └── server.ts            # Server client
│   ├── utils/
│   │   └── cn.ts                # classnames helper
│   └── constants.ts
│
├── types/                       # TypeScript types
│   ├── database.ts              # Supabase generated types
│   └── index.ts
│
└── hooks/                       # Custom React hooks
    ├── use-users.ts
    └── use-stats.ts
```

---

## Consequences

### ✅ Positive

1. **Fast Development** — Layered is straightforward, minimal boilerplate
2. **Easy to Understand** — Clear separation: UI → Logic → Data
3. **Feature Isolation** — Each feature is self-contained, easy to modify
4. **Solo-Friendly** — No complex abstractions that require team coordination
5. **Maintainable** — When scaling, can progressively evolve to Clean Architecture

### ⚠️ Tradeoffs

1. **Less Testable** — Compared to Clean Architecture, harder to unit test business logic
2. **Tight Coupling Risk** — Data layer may become tightly coupled to UI if not careful
3. **Refactor Cost** — If scaling to 10K+ users, may need to refactor to Clean Architecture

### 🔄 Migration Path

If CatatCuan scales beyond Phase 2:
- Extract `domain` layer properly with pure Dart entities
- Introduce repository interfaces (ports)
- Move to Clean Architecture gradually per feature

---

## Alternatives Considered

| Alternative | Reason Not Chosen |
|-------------|-------------------|
| **Clean Architecture** | Overkill for MVP, adds unnecessary complexity |
| **Hexagonal (Ports/Adapters)** | Too abstract for solo developer timeline |
| **Simple MVC** | Too flat, won't scale even to Phase 1.5 |

---

## References

- [Flutter Clean Architecture Best Practices 2024](https://dhiwise.com)
- [Next.js 14 App Router Structure](https://nextjs.org/docs)
- Planning Blueprint: `10_planning_blueprint.md`

---

*Generated by /choose-architecture workflow (WF-D01)*
*Rule Applied: RULE-D01 (ADR Required)*
