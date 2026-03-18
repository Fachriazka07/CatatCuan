---
description: Setup GitFlow branching strategy untuk project
---

# /git_branch - Git Branching Strategy Workflow

**ID:** WF-GIT02 | **Phase:** Any | **Context:** Solo ⭐ | Team ⭐⭐⭐ | Enterprise ⭐⭐⭐

---

## 🎯 Purpose

Memandu setup branching strategy berdasarkan GitFlow model. Memastikan semua branch memiliki naming convention yang konsisten dan workflow yang jelas.

---

## 🌿 GitFlow Branching Model

```
                            ┌─────────────┐
                            │   hotfix/*  │ ── Quick production fixes
                            └──────┬──────┘
                                   │
    ┌──────────────────────────────┼──────────────────────────────┐
    │                              │                              │
    │                              ▼                              │
    │                    ┌─────────────────┐                      │
    │                    │      main       │ ── Production-ready  │
    │                    └────────┬────────┘                      │
    │                             │                               │
    │                    ┌────────┴────────┐                      │
    │                    │    release/*    │ ── Release prep      │
    │                    └────────┬────────┘                      │
    │                             │                               │
    │                    ┌────────┴────────┐                      │
    │                    │     develop     │ ── Integration       │
    │                    └────────┬────────┘                      │
    │                             │                               │
    │         ┌───────────────────┼───────────────────┐           │
    │         │                   │                   │           │
    │    ┌────┴────┐        ┌─────┴─────┐       ┌─────┴─────┐     │
    │    │feature/A│        │ feature/B │       │ feature/C │     │
    │    └─────────┘        └───────────┘       └───────────┘     │
    │                                                             │
    └─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ STEP-BY-STEP

### Step 1: Check Current Branch Status

**AI WAJIB jalankan:**

```bash
git branch -a
git remote -v
```

---

### Step 2: Determine Strategy (AI asks user)

**AI tanyakan:**

1. **Project type?**

   - `[ ] Solo project` → Simplified GitFlow
   - `[ ] Team project` → Full GitFlow
   - `[ ] Open source` → Fork-based flow

2. **Deployment model?**
   - `[ ] Single environment` → main only
   - `[ ] Staging + Production` → develop + main
   - `[ ] Multiple environments` → develop + staging + main

---

### Step 3: Initialize Branch Structure

#### For Solo Project (Simplified)

```bash
# Create develop branch from main
git checkout main
git checkout -b develop
git push -u origin develop

# Set develop as default working branch
```

**Branch Structure:**

- `main` — Production
- `develop` — Working branch
- `feature/*` — New features

#### For Team Project (Full GitFlow)

```bash
# Ensure main exists
git checkout main

# Create develop branch
git checkout -b develop
git push -u origin develop

# Create release branch template (when ready)
# git checkout -b release/v1.0.0 develop
```

**Branch Structure:**

- `main` — Production (protected)
- `develop` — Integration (protected)
- `feature/*` — New features
- `release/*` — Release preparation
- `hotfix/*` — Production fixes

---

### Step 4: Configure Branch Protection (Team/Enterprise)

**AI generate GitHub CLI commands:**

```bash
# Protect main branch
gh api repos/{owner}/{repo}/branches/main/protection \
  -X PUT \
  -f required_status_checks='{"strict":true,"contexts":[]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"required_approving_review_count":1}'

# Protect develop branch
gh api repos/{owner}/{repo}/branches/develop/protection \
  -X PUT \
  -f required_pull_request_reviews='{"required_approving_review_count":1}'
```

---

### Step 5: Document Branch Naming Convention

**AI generate convention document:**

```markdown
## Branch Naming Convention

### Prefixes

| Prefix    | Purpose                 | Example                       |
| --------- | ----------------------- | ----------------------------- |
| feature/  | New features            | feature/user-authentication   |
| bugfix/   | Bug fixes               | bugfix/login-validation-error |
| hotfix/   | Critical production fix | hotfix/security-patch         |
| release/  | Release preparation     | release/v1.2.0                |
| refactor/ | Code refactoring        | refactor/database-queries     |
| docs/     | Documentation           | docs/api-documentation        |
| test/     | Test additions          | test/unit-testing-setup       |
| chore/    | Maintenance tasks       | chore/update-dependencies     |

### Rules

1. Use lowercase with hyphens (kebab-case)
2. Keep names short but descriptive
3. Include ticket number if applicable: `feature/JIRA-123-user-auth`
4. Delete branch after merge
```

---

## 📝 Branch Workflows

### Create Feature Branch

```bash
# From develop
git checkout develop
git pull origin develop
git checkout -b feature/{feature-name}

# Work on feature...
git add .
git commit -m "feat: add {feature}"

# Push and create PR
git push -u origin feature/{feature-name}
```

### Create Release Branch

```bash
# From develop
git checkout develop
git pull origin develop
git checkout -b release/v{X.Y.Z}

# Bump version, final fixes
git commit -m "chore: bump version to vX.Y.Z"

# Merge to main
git checkout main
git merge --no-ff release/v{X.Y.Z}
git tag -a v{X.Y.Z} -m "Release vX.Y.Z"

# Merge back to develop
git checkout develop
git merge --no-ff release/v{X.Y.Z}

# Delete release branch
git branch -d release/v{X.Y.Z}
```

### Create Hotfix Branch

```bash
# From main
git checkout main
git pull origin main
git checkout -b hotfix/{fix-name}

# Fix the issue
git commit -m "fix: {critical fix}"

# Merge to main
git checkout main
git merge --no-ff hotfix/{fix-name}
git tag -a v{X.Y.Z} -m "Hotfix vX.Y.Z"

# Merge to develop
git checkout develop
git merge --no-ff hotfix/{fix-name}

# Delete hotfix branch
git branch -d hotfix/{fix-name}
```

---

## ✅ Output Checklist

- [ ] Current branches reviewed
- [ ] Strategy determined (Solo/Team/Enterprise)
- [ ] develop branch created
- [ ] Branch protection configured (if Team/Enterprise)
- [ ] Naming convention documented
- [ ] Team informed of workflow

---

## 🔗 Related Workflows

| Workflow         | Purpose                    |
| ---------------- | -------------------------- |
| `/git_commit`    | Commit with proper message |
| `/git_tag`       | Create release tags        |
| `/git_changelog` | Generate CHANGELOG         |
| `/git_pr`        | Create pull request        |

---

## 📚 References

- [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Atlassian Git Workflows](https://www.atlassian.com/git/tutorials/comparing-workflows)
