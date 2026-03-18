---
description: Create feature/bugfix branch and manage development workflow
---

# /git_feature - Feature Branch Workflow

**ID:** WF-GIT06 | **Phase:** Development | **Context:** Solo ⭐ | Team ⭐⭐⭐ | Enterprise ⭐⭐⭐

---

## 🎯 Purpose

Memandu pembuatan feature branch, development workflow, dan merge process. Memastikan setiap feature dikembangkan secara isolated dan dapat di-review.

---

## 🌿 Feature Branch Flow

```
develop ──────────────────────────────────────────────▶
    │                                              │
    └─────┬────────────────────────────────┬───────┘
          │                                │
          │  feature/user-authentication   │
          │  ┌───────────────────────────┐ │
          └──┤ 1. Create  2. Develop     ├─┘
             │ 3. Commit  4. Push        │
             │ 5. PR      6. Merge       │
             └───────────────────────────┘
```

---

## 🛠️ STEP-BY-STEP

### Step 1: Sync with Develop

**AI jalankan:**

```bash
git checkout develop
git pull origin develop
```

---

### Step 2: Determine Branch Type (AI asks user)

**AI tanyakan:**

> "Apa yang akan dikerjakan?
>
> 1. `[ ] New feature` → feature/{name}
> 2. `[ ] Bug fix` → bugfix/{name}
> 3. `[ ] Refactoring` → refactor/{name}
> 4. `[ ] Documentation` → docs/{name}
> 5. `[ ] Testing` → test/{name}
> 6. `[ ] Hotfix (production)` → hotfix/{name}"

**AI tanyakan nama:**

> "Nama branch? (gunakan kebab-case)
> Examples: user-authentication, fix-login-error, update-readme"

---

### Step 3: Create Branch

**AI jalankan:**

```bash
# Feature branch
git checkout -b feature/{branch-name}

# Or bugfix
git checkout -b bugfix/{branch-name}

# Verify
git branch --show-current
```

---

### Step 4: Development Cycle

**AI guide development:**

```
┌─────────────────────────────────────────────────────────┐
│                  DEVELOPMENT CYCLE                      │
│                                                         │
│   1. Code → 2. Test → 3. Stage → 4. Commit → Repeat    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Commit template:**

```bash
# Small atomic commits
git add {files}
git commit -m "{type}: {short description}"

# Examples
git commit -m "feat: add login form component"
git commit -m "feat: implement JWT authentication"
git commit -m "test: add unit tests for auth service"
git commit -m "docs: add API documentation for auth endpoints"
```

---

### Step 5: Push Branch

**AI jalankan saat siap:**

```bash
git push -u origin {branch-type}/{branch-name}
```

---

### Step 6: Create Pull Request

**AI generate PR template:**

```markdown
## Description

{Brief description of changes}

## Type of Change

- [ ] New feature
- [ ] Bug fix
- [ ] Refactoring
- [ ] Documentation

## Changes Made

- {Change 1}
- {Change 2}
- {Change 3}

## Testing

- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] All tests passing

## Checklist

- [ ] Code follows project style guidelines
- [ ] Self-reviewed my code
- [ ] Commented complex logic
- [ ] Updated documentation
- [ ] No breaking changes

## Screenshots (if applicable)

{Add screenshots for UI changes}

## Related Issues

Closes #{issue_number}
```

**Using GitHub CLI:**

```bash
gh pr create \
  --title "{type}: {description}" \
  --body "{PR template content}" \
  --base develop \
  --head {branch-name}
```

---

### Step 7: After Merge

**AI jalankan setelah PR merged:**

```bash
# Switch to develop
git checkout develop

# Pull latest
git pull origin develop

# Delete local feature branch
git branch -d {branch-type}/{branch-name}

# Delete remote branch (usually auto-deleted)
git push origin --delete {branch-type}/{branch-name}
```

---

## 📝 Branch Naming Examples

| Type                | Example Branch Name                  |
| ------------------- | ------------------------------------ |
| Feature             | `feature/user-authentication`        |
| Feature with ticket | `feature/JIRA-123-user-auth`         |
| Bugfix              | `bugfix/login-validation-error`      |
| Hotfix              | `hotfix/security-patch-cve-2026`     |
| Refactor            | `refactor/optimize-database-queries` |
| Docs                | `docs/api-documentation`             |
| Test                | `test/add-auth-unit-tests`           |

---

## ⚠️ Best Practices

1. **Keep branches short-lived** — Merge within 1-3 days
2. **Small, focused changes** — One feature per branch
3. **Sync frequently** — Rebase with develop regularly
4. **Write tests** — Before or during feature development
5. **Self-review before PR** — Catch obvious issues

---

## 🔄 Rebase with Develop (if needed)

```bash
# On feature branch
git fetch origin
git rebase origin/develop

# Resolve conflicts if any
git add .
git rebase --continue

# Force push (only on feature branch!)
git push --force-with-lease
```

---

## ✅ Output Checklist

- [ ] Synced with develop
- [ ] Feature branch created
- [ ] Changes committed (atomic commits)
- [ ] Branch pushed to remote
- [ ] PR created with description
- [ ] PR reviewed and approved
- [ ] Branch merged
- [ ] Local branch deleted

---

## 🔗 Related Workflows

| Workflow      | Purpose                    |
| ------------- | -------------------------- |
| `/git_commit` | Commit with proper message |
| `/git_branch` | Branching strategy         |
| `/git_pr`     | Pull request workflow      |

---

## 📚 References

- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Feature Branch Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow)
