# CatatCuan - Risk Register

**Project ID:** PRJ-20260120-001
**Phase:** 01 (MVP)
**Date:** 2026-01-20
**Owner:** Fachri

---

## 📊 Summary

| Priority | Count | Action |
|----------|-------|--------|
| 🔴 Critical (7-9) | 2 | Immediate action |
| 🟡 Medium (4-6) | 6 | Plan mitigation |
| 🟢 Low (1-3) | 4 | Monitor |
| **TOTAL** | **12** | |

---

## 📋 Risk Register

| ID | Risk | Category | Prob | Impact | Score | Priority | Mitigation | Owner |
|----|------|----------|------|--------|-------|----------|------------|-------|
| R01 | **Scope Creep** — Adding features during development | Schedule | H(3) | H(3) | **9** | 🔴 Critical | Strict Out of Scope list, "trade-off" rule | Fachri |
| R02 | **PowerSync Learning Curve** — Complex sync logic | Technical | M(2) | H(3) | **6** | 🟡 Medium | Follow tutorials, allocate extra week | Fachri |
| R03 | **Low-end Device Performance** — App laggy on 2GB RAM | Technical | M(2) | H(3) | **6** | 🟡 Medium | Lightweight UI, optimize queries | Fachri |
| R04 | **Part-time Development Delays** — Limited hours/week | Resource | H(3) | M(2) | **6** | 🟡 Medium | 30% buffer, prioritize ruthlessly | Fachri |
| R05 | **User Adoption Resistance** — Target users not tech-savvy | External | M(2) | H(3) | **6** | 🟡 Medium | Extreme simplicity, onboarding | Fachri |
| R06 | **Data Loss During Sync** — Conflict resolution fails | Technical | L(1) | H(3) | **3** | 🟢 Low | Last-write-wins, backup before sync | Fachri |
| R07 | **Supabase Free Tier Limit** — Exceed 500MB database | Technical | L(1) | M(2) | **2** | 🟢 Low | Monitor usage, optimize storage | Fachri |
| R08 | **Play Store Rejection** — Policy violation | External | L(1) | H(3) | **3** | 🟢 Low | Follow guidelines, privacy policy | Fachri |
| R09 | **Solo Dev Burnout** — Overwhelmed with all responsibilities | Resource | M(2) | M(2) | **4** | 🟡 Medium | Realistic timeline, breaks, small wins | Fachri |
| R10 | **Beta Tester No-show** — Can't get feedback | External | M(2) | M(2) | **4** | 🟡 Medium | Recruit early, offer incentives | Fachri |
| R11 | **Security Vulnerability** — Data breach | Technical | L(1) | H(3) | **3** | 🟢 Low | Supabase RLS, encrypt sensitive data | Fachri |
| R12 | **Competitor Copies Feature** — BukuWarung adds simple mode | External | H(3) | H(3) | **9** | 🔴 Critical | First mover advantage, brand loyalty, iterate fast | Fachri |

---

## 🔴 Critical Risks (Score 7-9)

### R01: Scope Creep

| Attribute | Value |
|-----------|-------|
| **Score** | 9 (Critical) |
| **Category** | Schedule |
| **Description** | Adding features during development that weren't in MVP scope |
| **Trigger** | "Oh, it would be nice to also add X..." during coding |
| **Impact** | Delays launch, reduces quality, burnout |

**Mitigation Strategy:**
1. Refer to `08_scope_statement.md` before adding ANY feature
2. Apply "trade-off rule": if something goes in, something must go out
3. Add all new ideas to Phase 1.5/2 bucket immediately
4. Weekly self-review: "Am I building what's in scope?"

**Contingency Plan:**
If scope creep happens despite mitigation:
- Cut the lowest priority "Should Have" feature
- Extend timeline by max 1 week

---

### R12: Competitor Copies Feature

| Attribute | Value |
|-----------|-------|
| **Score** | 9 (Critical) |
| **Category** | External |
| **Description** | Well-funded competitors (BukuWarung, Lummo) notice the simple mode gap and copy the approach |
| **Trigger** | Competitor announces "Simple Mode" or similar feature |
| **Impact** | Reduced market opportunity, harder user acquisition |

**Mitigation Strategy:**
1. **Launch fast** — First mover advantage
2. **Build loyalty** — Personal touch with beta testers
3. **Iterate rapidly** — Listen to user feedback, ship weekly
4. **Focus on UX** — They can copy features, not the user experience
5. **Niche down** — Be "THE app for warung", not general UMKM

**Contingency Plan:**
If competitor launches similar feature:
- Double down on simplicity and speed
- Add unique features from Phase 1.5 faster
- Compete on price (freemium vs their subscription)

---

## 🟡 Medium Risks (Score 4-6)

### R02: PowerSync Learning Curve

| Attribute | Value |
|-----------|-------|
| **Score** | 6 (Medium) |
| **Trigger** | Unable to implement sync after 3 days of trying |

**Mitigation:**
- Study official PowerSync + Supabase tutorial first
- Allocate 1 extra week in Week 5 buffer
- Fallback: Simple manual sync if PowerSync too complex

---

### R03: Low-end Device Performance

| Attribute | Value |
|-----------|-------|
| **Score** | 6 (Medium) |
| **Trigger** | App crashes or lags on test device with 2GB RAM |

**Mitigation:**
- Use lightweight widgets, avoid heavy animations
- Lazy load data, pagination for reports
- Test on low-end device throughout development
- Profile with Flutter DevTools

---

### R04: Part-time Development Delays

| Attribute | Value |
|-----------|-------|
| **Score** | 6 (Medium) |
| **Trigger** | Behind schedule by more than 3 days |

**Mitigation:**
- 30% buffer already in timeline
- Track progress weekly
- If behind: cut "Should Have" features first
- Avoid perfectionism, ship "good enough"

---

### R05: User Adoption Resistance

| Attribute | Value |
|-----------|-------|
| **Score** | 6 (Medium) |
| **Trigger** | Beta testers give up after first use |

**Mitigation:**
- 3-slide onboarding tutorial
- Big buttons (min 64dp touch target)
- High contrast colors
- "Catat pertama" prompt on empty state
- WhatsApp support for questions

---

### R09: Solo Dev Burnout

| Attribute | Value |
|-----------|-------|
| **Score** | 4 (Medium) |
| **Trigger** | Dreading opening the project, missed 3+ days |

**Mitigation:**
- Celebrate small wins (each feature completed)
- Take weekends off (seriously)
- Don't chase perfection
- Remember: MVP, not final product

---

### R10: Beta Tester No-show

| Attribute | Value |
|-----------|-------|
| **Score** | 4 (Medium) |
| **Trigger** | Less than 3 beta testers available |

**Mitigation:**
- Recruit from interview contacts NOW
- Offer incentive (free premium forever)
- Ask friends/family who own small shops
- Goal: 5 beta testers committed by Week 6

---

## 🟢 Low Risks (Score 1-3)

| ID | Risk | Mitigation |
|----|------|------------|
| R06 | Data Loss During Sync | Last-write-wins default, test sync thoroughly |
| R07 | Supabase Free Tier | Monitor, optimize, upgrade if needed ($25/mo) |
| R08 | Play Store Rejection | Follow policies, add privacy policy |
| R11 | Security Vulnerability | Use Supabase RLS, no sensitive data stored locally |

---

## 📅 Risk Review Schedule

| Phase | Review Date | Focus |
|-------|-------------|-------|
| Week 2 | 03 Feb 2026 | Technical risks (R02, R03) |
| Week 4 | 17 Feb 2026 | Schedule risks (R01, R04) |
| Week 6 | 03 Mar 2026 | External risks (R05, R10) |
| Week 8 | 15 Mar 2026 | Launch risks (R08, R12) |

---

## 📊 Risk Heat Map

```
         LOW IMPACT    MEDIUM IMPACT    HIGH IMPACT
         (1)           (2)              (3)
       ┌─────────────┬─────────────────┬─────────────────┐
HIGH   │             │     R04         │   R01 ⚠️        │
(3)    │             │                 │   R12 ⚠️        │
       ├─────────────┼─────────────────┼─────────────────┤
MEDIUM │             │  R09  R10       │  R02  R03  R05  │
(2)    │             │                 │                 │
       ├─────────────┼─────────────────┼─────────────────┤
LOW    │             │     R07         │  R06  R08  R11  │
(1)    │             │                 │                 │
       └─────────────┴─────────────────┴─────────────────┘
        PROBABILITY
```

---

## ✅ Risk Checklist

- [x] Minimum 3 risks identified (12 total)
- [x] Each risk scored (Probability × Impact)
- [x] Mitigation strategies defined
- [x] Owners assigned (Fachri for all)
- [x] Critical risks have contingency plans
- [x] Review schedule created
- [x] Report saved

---

## 🔄 Next Steps

| # | Action | Workflow | Priority |
|---|--------|----------|----------|
| 1 | Compile all planning docs | `/compile-blueprint` | High |
| 2 | Start Design Phase | `/design-tier-assessment` | Next Phase |

---

*Generated by Risk Register Workflow (WF-P12)*
*Rules Applied: RULE-P08 (Risk Identification Minimum — 3 risks required, 12 identified)*
*Date: 2026-01-20*
