---
description: Initialize git repository with proper structure for new project
---

# /git_init - Git Initialization Workflow

**ID:** WF-GIT05 | **Phase:** Planning/Development | **Context:** Solo ⭐ | Team ⭐⭐ | Enterprise ⭐⭐⭐

---

## 🎯 Purpose

Memandu inisialisasi git repository untuk project baru dengan konfigurasi yang proper, termasuk .gitignore, branch structure, dan initial commit.

---

## 🛠️ STEP-BY-STEP

### Step 1: Check Existing Repository

**AI WAJIB cek:**

```bash
git status 2>/dev/null && echo "Git already initialized" || echo "No git repo"
ls -la .git 2>/dev/null
```

---

### Step 2: Determine Project Type (AI asks user)

**AI tanyakan:**

1. **Project type?**

   - `[ ] Node.js/JavaScript`
   - `[ ] Python`
   - `[ ] Go`
   - `[ ] Rust`
   - `[ ] Generic`

2. **Framework?**

   - `[ ] Next.js`
   - `[ ] React`
   - `[ ] Vue/Nuxt`
   - `[ ] Express`
   - `[ ] FastAPI`
   - `[ ] Other: ___`

3. **Database?**
   - `[ ] PostgreSQL`
   - `[ ] MySQL`
   - `[ ] MongoDB`
   - `[ ] SQLite`
   - `[ ] None`

---

### Step 3: Initialize Repository

**AI jalankan:**

```bash
git init
```

---

### Step 4: Create .gitignore

**AI generate .gitignore berdasarkan project type:**

#### Node.js / JavaScript

```gitignore
# Dependencies
node_modules/
.pnpm-store/

# Build
dist/
build/
.next/
out/

# Environment
.env
.env.local
.env.*.local

# Logs
logs/
*.log
npm-debug.log*

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Testing
coverage/
.nyc_output/

# Misc
*.local
.turbo/
```

#### Python

```gitignore
# Byte-compiled
__pycache__/
*.py[cod]
*$py.class

# Virtual environments
venv/
.venv/
env/

# Environment
.env
.env.local

# IDE
.vscode/
.idea/

# Testing
.pytest_cache/
.coverage
htmlcov/

# Distribution
dist/
build/
*.egg-info/
```

#### Generic (All Projects)

```gitignore
# Environment
.env
.env.local
.env.*.local

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp

# Logs
*.log
logs/
```

---

### Step 5: Create Initial Files

**AI create files:**

#### README.md

````markdown
# {Project Name}

{Short description}

## Getting Started

### Prerequisites

- Node.js 20+
- npm/pnpm

### Installation

```bash
npm install
npm run dev
```
````

## License

MIT

````

#### .env.example

```env
# Database
DATABASE_URL=

# Authentication
JWT_SECRET=
SESSION_SECRET=

# External APIs
API_KEY=
````

---

### Step 6: Initial Commit

**AI jalankan:**

```bash
git add .
git commit -m "chore: initial project setup

- Initialize git repository
- Add .gitignore for {project_type}
- Add README.md
- Add .env.example"
```

---

### Step 7: Setup Remote (Optional)

**AI tanyakan:**

> "Apakah sudah ada remote repository?
>
> - `[ ] Ya, sudah ada` → Add remote
> - `[ ] Belum, buat baru` → Use gh cli
> - `[ ] Skip` → Setup later"

**Add existing remote:**

```bash
git remote add origin https://github.com/{user}/{repo}.git
git push -u origin main
```

**Create new with GitHub CLI:**

```bash
gh repo create {repo-name} --public --source=. --remote=origin --push
```

---

### Step 8: Setup Branching

**AI jalankan:**

```bash
# Ensure on main branch
git branch -M main

# Create develop branch
git checkout -b develop
git push -u origin develop

# Switch back to develop for working
git checkout develop
```

---

## ✅ Output Checklist

- [ ] Git initialized
- [ ] .gitignore created for project type
- [ ] README.md created
- [ ] .env.example created
- [ ] Initial commit made
- [ ] Remote configured (optional)
- [ ] Branch structure setup

---

## 🔗 Related Workflows

| Workflow       | Purpose                   |
| -------------- | ------------------------- |
| `/git_branch`  | Setup branching strategy  |
| `/git_commit`  | Commit guidelines         |
| `/new_feature` | Start feature development |

---

## 📚 References

- [gitignore.io](https://www.toptal.com/developers/gitignore)
- [GitHub: gitignore templates](https://github.com/github/gitignore)
