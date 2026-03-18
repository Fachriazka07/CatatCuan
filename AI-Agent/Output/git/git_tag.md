---
description: Create and manage release tags with semantic versioning
---

# /git_tag - Git Tagging Workflow

**ID:** WF-GIT03 | **Phase:** Deployment | **Context:** Solo ⭐ | Team ⭐⭐ | Enterprise ⭐⭐⭐

---

## 🎯 Purpose

Memandu pembuatan release tags menggunakan Semantic Versioning (SemVer). Tags digunakan untuk menandai release versions yang siap untuk production.

---

## 📊 Semantic Versioning

```
v{MAJOR}.{MINOR}.{PATCH}[-{pre-release}][+{build}]

Examples:
v1.0.0          # Stable release
v1.0.1          # Patch/bugfix
v1.1.0          # New feature (backward compatible)
v2.0.0          # Breaking changes
v1.0.0-alpha.1  # Pre-release alpha
v1.0.0-beta.2   # Pre-release beta
v1.0.0-rc.1     # Release candidate
```

| Version   | When to Increment                 |
| --------- | --------------------------------- |
| **MAJOR** | Breaking/incompatible API changes |
| **MINOR** | New features, backward compatible |
| **PATCH** | Bug fixes, backward compatible    |

---

## 🛠️ STEP-BY-STEP

### Step 1: Check Current Tags

**AI WAJIB jalankan:**

```bash
git tag -l --sort=-v:refname | head -10
git describe --tags --abbrev=0 2>/dev/null || echo "No tags yet"
```

---

### Step 2: Determine Version Bump (AI asks user)

**AI tanyakan:**

1. **Ada breaking changes?**

   - `[ ] Ya` → Bump MAJOR
   - `[ ] Tidak`

2. **Ada new features?**

   - `[ ] Ya` → Bump MINOR
   - `[ ] Tidak`

3. **Hanya bug fixes?**

   - `[ ] Ya` → Bump PATCH

4. **Ini pre-release?**
   - `[ ] alpha` → v{X.Y.Z}-alpha.{N}
   - `[ ] beta` → v{X.Y.Z}-beta.{N}
   - `[ ] rc` → v{X.Y.Z}-rc.{N}
   - `[ ] stable` → v{X.Y.Z}

---

### Step 3: Generate Version Number

**AI calculate next version:**

```python
# Logic
current = "v1.2.3"  # dari git describe
if breaking_change:
    next = "v2.0.0"
elif new_feature:
    next = "v1.3.0"
else:
    next = "v1.2.4"
```

**Contoh dialog:**

> "Current version: v1.2.3
>
> Changes detected:
>
> - feat: add user dashboard → MINOR
> - fix: login validation → PATCH
>
> Recommended: v1.3.0
>
> Confirm version?"

---

### Step 4: Create Annotated Tag

**AI jalankan:**

```bash
# Create annotated tag
git tag -a v{VERSION} -m "Release v{VERSION}

Features:
- {feature 1}
- {feature 2}

Fixes:
- {fix 1}

Breaking Changes:
- {if any}"
```

**Untuk lightweight tag (not recommended):**

```bash
git tag v{VERSION}
```

---

### Step 5: Push Tag to Remote

**AI jalankan:**

```bash
# Push specific tag
git push origin v{VERSION}

# Or push all tags
git push origin --tags
```

---

### Step 6: Verify Tag

**AI jalankan:**

```bash
git show v{VERSION}
```

---

## 📝 Tag Message Templates

### Stable Release

```
Release v1.0.0

🎉 Initial stable release!

Features:
- User authentication with JWT
- Dashboard with analytics
- REST API with OpenAPI spec

Documentation:
- API documentation complete
- Getting Started guide added
```

### Feature Release

```
Release v1.2.0

✨ New Features:
- Add user profile editing
- Add dark mode support
- Add export to PDF

🐛 Bug Fixes:
- Fix login redirect loop
- Fix mobile responsive issues

📚 Documentation:
- Update API docs for new endpoints
```

### Hotfix Release

```
Hotfix v1.2.1

🔥 Critical Fix:
- Fix security vulnerability in auth token

⚠️ This is a security patch. Please update immediately.
```

### Pre-release

```
Pre-release v2.0.0-beta.1

⚠️ This is a BETA release. Not for production use.

Breaking Changes:
- Removed deprecated endpoints
- Changed auth flow to OAuth2

New Features:
- Complete UI redesign
- New GraphQL API

Known Issues:
- Mobile layout incomplete
- Performance optimization pending
```

---

## 🗑️ Delete Tag (if needed)

```bash
# Delete local tag
git tag -d v{VERSION}

# Delete remote tag
git push origin --delete v{VERSION}
```

---

## ✅ Output Checklist

- [ ] Current tags reviewed
- [ ] Version bump determined
- [ ] Version number confirmed
- [ ] Annotated tag created with message
- [ ] Tag pushed to remote
- [ ] Tag verified

---

## 🔗 Related Workflows

| Workflow         | Purpose                      |
| ---------------- | ---------------------------- |
| `/git_commit`    | Commit before tagging        |
| `/git_branch`    | Release branch workflow      |
| `/git_changelog` | Generate CHANGELOG from tags |
| `/git_release`   | Create GitHub Release        |

---

## 📚 References

- [Semantic Versioning](https://semver.org/)
- [Git Tagging Basics](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
- [Keep a Changelog](https://keepachangelog.com/)
