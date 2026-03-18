---
description: Generate CHANGELOG.md from git history and tags
---

# /git_changelog - Changelog Generation Workflow

**ID:** WF-GIT04 | **Phase:** Deployment | **Context:** Solo ⭐ | Team ⭐⭐ | Enterprise ⭐⭐⭐

---

## 🎯 Purpose

Memandu pembuatan dan update CHANGELOG.md berdasarkan git history dan commits. CHANGELOG membantu users dan developers memahami perubahan antar versi.

---

## 📋 Changelog Format (Keep a Changelog)

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- New feature description

### Changed

- Change description

### Deprecated

- Soon-to-be removed feature

### Removed

- Removed feature

### Fixed

- Bug fix description

### Security

- Security fix description

## [1.0.0] - 2026-01-08

### Added

- Initial release features
```

---

## 🛠️ STEP-BY-STEP

### Step 1: Check Existing Changelog

**AI WAJIB cek:**

```bash
cat CHANGELOG.md 2>/dev/null || echo "No CHANGELOG.md found"
```

---

### Step 2: Get Commits Since Last Tag

**AI jalankan:**

```bash
# Get last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

# Get commits since last tag (or all commits if no tag)
if [ -n "$LAST_TAG" ]; then
  git log ${LAST_TAG}..HEAD --pretty=format:"- %s" --no-merges
else
  git log --pretty=format:"- %s" --no-merges | head -50
fi
```

---

### Step 3: Categorize Commits by Type

**AI analyze commit messages:**

| Prefix       | Category                |
| ------------ | ----------------------- |
| `feat:`      | Added                   |
| `fix:`       | Fixed                   |
| `docs:`      | Changed (Documentation) |
| `refactor:`  | Changed                 |
| `perf:`      | Changed (Performance)   |
| `test:`      | Changed (Tests)         |
| `chore:`     | Changed (Maintenance)   |
| `security:`  | Security                |
| `deprecate:` | Deprecated              |
| `remove:`    | Removed                 |

---

### Step 4: Generate Changelog Entry

**AI generate entry:**

```markdown
## [{version}] - {YYYY-MM-DD}

### Added

- {feat commits}

### Changed

- {refactor, docs, perf commits}

### Fixed

- {fix commits}

### Security

- {security commits}
```

---

### Step 5: Update CHANGELOG.md

**AI update file:**

1. Jika CHANGELOG.md tidak ada → Create new
2. Jika ada → Insert new version after `## [Unreleased]`

**Template untuk file baru:**

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [{version}] - {date}

### Added

{categorized changes}

---

[Unreleased]: https://github.com/{owner}/{repo}/compare/v{version}...HEAD
[{version}]: https://github.com/{owner}/{repo}/releases/tag/v{version}
```

---

## 📝 Example Changelog

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- Database migration workflow

## [1.2.0] - 2026-01-08

### Added

- User profile editing feature
- Dark mode support
- Export to PDF functionality

### Changed

- Updated dashboard layout
- Improved API response times

### Fixed

- Login redirect loop issue
- Mobile responsive layout bugs

### Security

- Updated dependencies to fix CVE-2026-1234

## [1.1.0] - 2026-01-01

### Added

- User authentication with JWT
- REST API with OpenAPI spec

### Fixed

- Form validation errors

## [1.0.0] - 2025-12-15

### Added

- Initial release
- Basic CRUD operations
- User registration

---

[Unreleased]: https://github.com/user/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/user/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/user/repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/user/repo/releases/tag/v1.0.0
```

---

## 🤖 Auto-generate with Tools

### Using git-cliff

```bash
# Install
cargo install git-cliff

# Generate
git-cliff --output CHANGELOG.md
```

### Using conventional-changelog

```bash
# Install
npm install -g conventional-changelog-cli

# Generate
conventional-changelog -p angular -i CHANGELOG.md -s
```

### Manual with Git

```bash
# Generate from commits
git log --pretty=format:"- %s (%h)" v1.0.0..v1.1.0 > release_notes.md
```

---

## ✅ Output Checklist

- [ ] Existing CHANGELOG.md checked
- [ ] Commits since last tag retrieved
- [ ] Commits categorized by type
- [ ] Version entry generated
- [ ] CHANGELOG.md updated
- [ ] Compare links updated
- [ ] File committed

---

## 🔗 Related Workflows

| Workflow       | Purpose                            |
| -------------- | ---------------------------------- |
| `/git_commit`  | Proper commit format for changelog |
| `/git_tag`     | Create version tags                |
| `/git_release` | Create GitHub Release              |

---

## 📚 References

- [Keep a Changelog](https://keepachangelog.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [git-cliff](https://git-cliff.org/)
