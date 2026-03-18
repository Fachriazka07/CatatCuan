---
description: Generate comprehensive git commit message with structured changelog format
---

# /git_commit - Git Commit Workflow

**ID:** WF-GIT01 | **Phase:** Any | **Context:** Solo ⭐ | Team ⭐⭐ | Enterprise ⭐⭐⭐

---

## 🎯 Purpose

Memandu AI untuk menghasilkan commit message yang comprehensive dan terstruktur berdasarkan semua perubahan di working directory.

**Format:** Conventional Commits + Changelog Style

---

## 🛠️ STEP-BY-STEP

### Step 1: Check Git Status

**AI WAJIB jalankan:**

```bash
git status --short
```

**Analisis output:**

- `M` = Modified
- `A` = Added
- `D` = Deleted
- `R` = Renamed
- `??` = Untracked

---

### Step 2: Add All Changes

**AI jalankan:**

```bash
git add -A
```

**Lalu verifikasi:**

```bash
git status --short
```

---

### Step 3: Analyze Changes by Category

**AI WAJIB kategorikan perubahan:**

| Category                 | Pattern                  | Example Files                               |
| ------------------------ | ------------------------ | ------------------------------------------- |
| **Folder Restructuring** | R (Renamed), banyak file | `output_rules/{} -> output_rules/design/{}` |
| **Workflow Enhancement** | M pada workflow files    | `design_api.md`, `choose_architecture.md`   |
| **Rule Updates**         | M/A pada rule files      | `RULE-SEC01.md`, `RULE-DB01.md`             |
| **Documentation**        | M/A pada README, usecase | `README.md`, `usecase/`                     |
| **Knowledge Base**       | A pada knowledge/        | `KNOW_*.md`                                 |
| **Configuration**        | M/A pada config          | `AI_AGENT_INSTALL.md`, `index.md`           |

---

### Step 4: Generate Commit Type

**Conventional Commits prefix:**

| Type        | When to Use                             |
| ----------- | --------------------------------------- |
| `feat:`     | New feature, workflow, or capability    |
| `fix:`      | Bug fix, correction                     |
| `docs:`     | Documentation only                      |
| `refactor:` | Restructuring without changing behavior |
| `chore:`    | Maintenance, dependencies               |
| `style:`    | Formatting, no code change              |

---

### Step 5: Generate Commit Message Template

**AI WAJIB generate dengan format:**

```
{type}: {Short summary max 72 chars}

{Category 1 Header}:
- {Change 1}
- {Change 2}

{Category 2 Header}:
- {Change 1}
- {Change 2}

{Scores/Stats if applicable}:
- {Metric}: {Value}
```

---

### Step 6: Execute Commit

**AI jalankan:**

```bash
git commit -m "{generated message}"
```

> ⚠️ **Note:** Untuk multiline message, gunakan format:
>
> ```bash
> git commit -m "First line" -m "Second paragraph" -m "Third paragraph"
> ```

Atau gunakan heredoc untuk message panjang:

```bash
git commit -m "feat: Short summary

Category 1:
- Change 1
- Change 2

Category 2:
- Change 3"
```

---

## 📝 Example Commit Messages

### Example 1: Feature Commit

```
feat: Design Phase enterprise upgrade & Planning-Design transition alignment

Folder Restructuring:
- Restructure output_rules/ into design/ and development/ subdirectories
- Rename planning_team_startup/ to planning_team/ for consistency
- Move 51 rules into proper tier-based structure (solo/team/security)

Design Phase Enhancement (8 workflows updated with Deep Research):
- Add search_web + read_url_content pattern to choose_architecture.md
- Add search_web pattern to design_api.md, design_database.md, design_ui_ux.md
- Add search_web pattern to threat_model.md, security_checklist.md
- Add search_web pattern to secrets_design.md, vulnerability_checklist.md

Language-Agnostic Updates (4 workflows):
- Make tech stack options dynamic in choose_architecture.md
- Make database/ORM options dynamic in design_database.md
- Make component library options dynamic in design_ui_ux.md
- Read from Planning Phase output first before asking

Audit Scores:
- Design Phase: 91/100 (IEEE 42010 + TOGAF aligned)
- 37 workflows verified across Design Phase
- 51 rules verified across design tiers
```

### Example 2: Documentation Commit

```
docs: Update README and add usage examples

Documentation:
- Add Getting Started section to README.md
- Add code examples for API usage
- Update installation instructions

Examples:
- Add example_basic.md with simple workflow
- Add example_advanced.md with complex scenario
```

### Example 3: Fix Commit

```
fix: Correct tier threshold alignment between phases

Bug Fixes:
- Fix budget threshold mismatch ($10K for Tier 2+)
- Fix tier inheritance logic in design_tier_assessment.md
- Correct folder reference from planning_team_startup to planning_team

Affected Files:
- output_workflow/design/design_tier_assessment.md
- output_workflow/planning/planning_tier_assessment.md
- usecase/planning/README.md
```

---

## ✅ Output Checklist

- [ ] Git status checked
- [ ] All changes staged (git add -A)
- [ ] Changes categorized
- [ ] Commit type selected (feat/fix/docs/refactor/chore)
- [ ] Commit message generated with proper format
- [ ] Commit executed successfully

---

## 🔗 Related Workflows

| Workflow         | Purpose                   |
| ---------------- | ------------------------- |
| `/git_branch`    | Create branching strategy |
| `/git_tag`       | Create release tags       |
| `/git_changelog` | Generate CHANGELOG.md     |

---

## 📚 References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Git Best Practices](https://git-scm.com/book/en/v2)
