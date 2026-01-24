# AI-Agent Installer

> **Instruksi untuk AI Agent:** File ini adalah installer untuk AI-Agent. Saat user men-mention file ini, jalankan instruksi di bawah secara berurutan untuk menginstall AI-Agent di workspace aktif.

---

## 🚀 Cara Penggunaan (untuk User)

1. Download file ini ke folder project Anda
2. Buka Antigravity/IDE dengan AI agent
3. Mention file ini: `@AI_AGENT_INSTALL.md install`
4. Agent akan membuat struktur folder dan file yang diperlukan

---

## 📦 Instalasi (untuk AI Agent)

Saat user meminta install, jalankan langkah-langkah berikut:

### Step 1: Buat Struktur Folder

Buat folder-folder berikut di root workspace:

```
AI-Agent/
+-- Topic/
+-- Plan/
+-- Find/
+-- Knowledge/
|   +-- general/
+-- Research/
+-- Log/
|   +-- context_handoff/       <- Context handoff files antar chat session
|       +-- archive/           <- Archived handoff files
+-- Output/                    <- Workflow outputs (6 SDLC Phases)
    +-- Planning/              <- Phase 1: Project Charter, SRS
    +-- Design/                <- Phase 2: Architecture, ERD, API, UI/UX
    +-- Development/           <- Phase 3: Code, Documentation
    +-- Testing/               <- Phase 4: Test Reports, Bug Reports
    +-- Deployment/            <- Phase 5: Deployment Logs, Live App
    +-- Maintenance/           <- Phase 6: Updates, Patches, Hotfixes

.agent/
+-- STANDARDS.md

scripts/
+-- (Python automation scripts)
```

### Step 2: Buat STANDARDS.md

Buat file `.agent/STANDARDS.md` dengan konten berikut:

```markdown
# AI-Agent Standards & Conventions

Dokumen ini adalah **Single Source of Truth** untuk semua konvensi penamaan, struktur file, dan prosedur operasional di dalam AI-Agent. Semua workflow **WAJIB** merujuk ke dokumen ini pada langkah pertama.

---

## 1. Konvensi Penamaan (Naming Convention)

### A. Format ID

Gunakan **Underscore (`_`)** sebagai pemisah antar komponen ID, bukan dash (`-`).

- **Topic:** `TOPIC_NNN` (Contoh: `TOPIC_001`)
- **Plan:** `PLAN_NNN` (Contoh: `PLAN_001`)
- **Finding:** `FIND_NNN` (Contoh: `FIND_001`)
- **Knowledge:** `K_NNN` (Contoh: `K_001`)

### B. Slug & Nama File

Format: `{ID}_{slug}.md`

- **Slug:** 2-4 kata, lowercase, dipisahkan underscore.
- **Contoh Benar:** `TOPIC_001_project_setup.md`

---

## 2. Struktur Folder & Lokasi

- **Topic:** `AI-Agent/Topic/`
- **Plan:** `AI-Agent/Plan/`
- **Finding:** `AI-Agent/Find/`
- **Knowledge:** `AI-Agent/Knowledge/{domain}/`
- **Log:** `AI-Agent/Log/`
- **Output:** `AI-Agent/Output/{Phase}/{ProjectName}/`
- **Standards:** `.agent/STANDARDS.md` (Dokumen ini)

### Output Folder Rules

- **Path Pattern:** `AI-Agent/Output/{Phase}/{ProjectName}/{phase}_{filename}.md`
- **6 SDLC Phases:** Planning, Design, Development, Testing, Deployment, Maintenance
- **Naming:** `{phase}` = Phase version (01, 02, 03... for Phase 1, 2, 3...)
- **Example:** `AI-Agent/Output/Planning/PortfolioWebsite/01_project_charter.md` (Phase 1)
- **Phase 2 Example:** `AI-Agent/Output/Design/PortfolioWebsite/02_database_erd.md`

---

## 3. Prinsip Dasar (HHH)

1. **Helpfulness (Kemanfaatan):** Berusaha maksimal memberikan solusi efektif.
2. **Harmlessness (Ketidakberbahayaan):** Tidak merusak sistem atau data.
3. **Honesty (Kejujuran):** Transparan tentang limitasi dan ketidakpastian.

---

## 4. Prosedur Update Index

Setiap kali membuat artefak baru, Agent **WAJIB** mengupdate file `index.md` di folder terkait.

---

## 5. Prosedur Logging

Setiap aksi signifikan dicatat di `AI-Agent/Log/aktivitas.md`:

- Format: `| {HH:mm} | {Aktivitas} | {ID} | {Keterangan} |`

---

## 6. Context Handoff

Ketika context window mendekati limit (≥80%), AI WAJIB menyimpan context ke `AI-Agent/Log/context_handoff/`:

- **File:** `HANDOFF_{YYYY-MM-DD}_{topic}.md`
- **Trigger:** `/continue` untuk load context di chat baru

---

## 7. Self-Learning

Setiap kegagalan tool/command dicatat di `AI-Agent/Log/failures.md` untuk pembelajaran.

---

## 8. Filosofi AI-Agent

AI-Agent adalah **mesin berpikir eksternal** — perpanjangan pikiran yang belajar dari cara user bekerja, bukan user yang beradaptasi dengan Agent.
```

### Step 3: Buat Index Files

**File: `AI-Agent/Topic/index.md`**

```markdown
# Index Topik

## 💬 Aktif

| ID  | Judul | Status | Prioritas |
| :-- | :---- | :----- | :-------- |

## 📦 Arsip

| ID  | Judul | Status |
| :-- | :---- | :----- |

**Ringkasan:** 💬 0 Aktif | 📦 0 Arsip
```

**File: `AI-Agent/Plan/index.md`**

```markdown
# Index Plan

## 🏗️ In Progress

| ID  | Judul | Prioritas | Status |
| :-- | :---- | :-------- | :----- |

## 📋 Backlog

| ID  | Judul | Prioritas | Status |
| :-- | :---- | :-------- | :----- |

## 📦 Arsip

| ID  | Judul | Status |
| :-- | :---- | :----- |

**Ringkasan:** 🏗️ 0 Active | 📋 0 Backlog | 📦 0 Arsip
```

**File: `AI-Agent/Find/index.md`**

```markdown
# Index Finding

## 🔍 Open

| ID  | Judul | Prioritas |
| :-- | :---- | :-------- |

## ✅ Resolved

| ID  | Judul |
| :-- | :---- |

**Ringkasan:** 🔍 0 Open | ✅ 0 Resolved
```

**File: `AI-Agent/Knowledge/index.md`**

```markdown
# Index Knowledge Base

> **Tujuan:** Menyimpan domain knowledge secara terstruktur untuk referensi Agent.

## 📚 Domain Knowledge

| Domain              | Deskripsi      | Jumlah Entry |
| :------------------ | :------------- | :----------- |
| [general](general/) | Knowledge umum | 0            |

**Statistik:** 1 Domain | 0 Entries
```

**File: `AI-Agent/Knowledge/general/index.md`**

```markdown
# 📁 Knowledge/general Index

> Auto-generated

---

## Daftar Knowledge/general (0 items)

| File | Title | Summary |
| ---- | ----- | ------- |

---

_Updated by auto_index_updater.py_
```

**File: `AI-Agent/Research/index.md`**

```markdown
# Index Research

> Hasil riset mendalam yang telah dilakukan.

## 📚 Research Entries

| File | Judul | Tanggal |
| :--- | :---- | :------ |

**Statistik:** 0 Entries
```

**File: `AI-Agent/Output/index.md`**

```markdown
# Index Output

> Hasil output dari semua workflow per-phase.

## 📁 Phase Folders

| Phase                        | Deskripsi                               | Projects |
| :--------------------------- | :-------------------------------------- | :------- |
| [Planning/](Planning/)       | Output dari Planning Phase workflows    | 0        |
| [Design/](Design/)           | Output dari Design Phase workflows      | 0        |
| [Development/](Development/) | Output dari Development Phase workflows | 0        |
| [Deployment/](Deployment/)   | Output dari Deployment Phase workflows  | 0        |

**Statistik:** 4 Phases | 0 Projects
```

### Step 4: Buat Log Files

**File: `AI-Agent/Log/aktivitas.md`**

```markdown
# Log Aktivitas

---

## {TANGGAL_HARI_INI}

| Waktu          | Aktivitas | ID  | Keterangan                  |
| :------------- | :-------- | :-- | :-------------------------- |
| {JAM_SEKARANG} | Install   | -   | AI-Agent berhasil diinstall |
```

_(Ganti {TANGGAL_HARI_INI} dan {JAM_SEKARANG} dengan waktu aktual)_

**File: `AI-Agent/Log/failures.md`**

```markdown
# Failure Log

Log kegagalan tool/command untuk pembelajaran Agent.

---

## 📊 Statistik

| Tool          | Total Failures | Last Failure |
| ------------- | -------------- | ------------ |
| run_command   | 0              | -            |
| write_to_file | 0              | -            |

---

## 📝 Log Entries

<!-- Entries akan ditambahkan saat terjadi kegagalan -->

---

## 🔍 Identified Patterns

<!-- Pattern yang teridentifikasi dari ≥3 failure serupa -->

---

## 🧪 Test Cases

> Test cases untuk validasi ulang pattern yang sudah teridentifikasi.
> Dijalankan saat `/self_audit` jika pattern berusia >7 hari.

<!-- Format:
### TC-{NNN} (Pattern: P-{NNN})
- **Command:** {command to test}
- **Setup:** {langkah persiapan}
- **Expected Result:** {hasil yang diharapkan jika pattern masih berlaku}
- **Cleanup:** {langkah pembersihan}
- **Created:** {YYYY-MM-DD}
- **Last Tested:** {YYYY-MM-DD atau -}
-->

---

## 📦 Archived Patterns

> Pattern yang sudah tidak berlaku lagi (obsolete).

<!-- Format:
### P-{NNN}: {Nama Pattern} [ARCHIVED]
- **Original Status:** {status sebelum archive}
- **Archived Date:** {tanggal archive}
- **Reason:** {alasan archive}
-->

_Belum ada pattern yang diarsipkan._
```

**File: `AI-Agent/Log/context_handoff/index.md`**

```markdown
# Context Handoff Index

> Menyimpan context dari chat sebelumnya untuk dilanjutkan di chat baru.

## 📋 Active Handoffs

| File | Topic | Status | Date |
| :--- | :---- | :----- | :--- |

## 📦 Archive

Lihat folder `archive/` untuk handoff lama.

**Statistik:** 0 Active | 0 Archived

---

### Cara Penggunaan

1. Ketika context ≥80%, AI akan otomatis save handoff
2. Di chat baru, gunakan `/continue` untuk load context
3. AI akan membaca file handoff terbaru dan melanjutkan
```

**File: `AI-Agent/Log/user_behaviour.md`**

```markdown
# User Behaviour Log

> **Tujuan:** Agent menjadi perpanjangan pikiran yang belajar dari cara user bekerja.

---

## 🧠 Learned Preferences (Aktif)

Preferensi yang sudah teridentifikasi dan **WAJIB** dipatuhi Agent.

### Komunikasi

- **Bahasa:** [Belum teridentifikasi]
- **Panjang respons:** [Belum teridentifikasi]

### Keputusan

- **Default pilihan:** [Belum teridentifikasi]

---

## 📝 Observation Log

Catatan observasi mentah yang belum jadi preference.

---

## 🔄 Pending Patterns

| Pattern ID | Deskripsi | Evidence | Threshold | Status |
| ---------- | --------- | -------- | --------- | ------ |

---

## 📊 Statistik

| Metrik              | Value |
| ------------------- | ----- |
| Total Observations  | 0     |
| Pending Patterns    | 0     |
| Learned Preferences | 0     |
```

### Step 5: Buat Folder Scripts (Opsional)

> **⚡ Python scripts mengoptimasi workflow repetitif dan mengurangi beban AI.** > **Isi script bisa di-copy manual dari GitHub setelah instalasi.**

**Buat folder dan file placeholder:**

```
scripts/
+-- analyze_workspace.py      <- Scan dan index semua file markdown
+-- auto_index_updater.py     <- Update semua index.md otomatis
+-- document_health_analyzer.py <- Cek kesehatan dokumen
+-- failure_analyzer.py       <- Analisis pattern kegagalan
```

**Buat file kosong untuk setiap script:**

```python
# scripts/analyze_workspace.py
# TODO: Copy isi dari GitHub repository
```

```python
# scripts/auto_index_updater.py
# TODO: Copy isi dari GitHub repository
```

```python
# scripts/document_health_analyzer.py
# TODO: Copy isi dari GitHub repository
```

```python
# scripts/failure_analyzer.py
# TODO: Copy isi dari GitHub repository
```

### Step 6: Konfirmasi

Setelah semua file dibuat, tampilkan:

```
✅ AI-Agent berhasil diinstall!

📁 Struktur:
- AI-Agent/ (Topic, Plan, Find, Knowledge, Research, Log, Output)
- AI-Agent/Output/ (Planning, Design, Development, Deployment)
- .agent/ (STANDARDS.md)
- scripts/ (Python automation - opsional)

� Index Files:
- Topic/index.md, Plan/index.md, Find/index.md
- Knowledge/index.md, Research/index.md, Output/index.md
- Log/context_handoff/index.md

📝 Log Files:
- aktivitas.md, failures.md, user_behaviour.md

💡 AI-Agent siap digunakan!
```

---

## 📋 Checklist Instalasi

- [ ] Folder `AI-Agent/` dibuat (dengan subfolder Topic, Plan, Find, Knowledge, Research, Log, Output)\r
- [ ] Folder `AI-Agent/Output/` dibuat (dengan subfolder Planning, Design, Development, Deployment)
- [ ] Folder `.agent/` dibuat dengan file STANDARDS.md
- [ ] Folder `scripts/` dibuat (opsional)
- [ ] File `STANDARDS.md` dibuat
- [ ] Semua `index.md` dibuat (termasuk Research/index.md, Knowledge/general/index.md, dan context_handoff/index.md)
- [ ] Semua log files dibuat (aktivitas.md, failures.md, user_behaviour.md)
- [ ] Folder `context_handoff/` dan `context_handoff/archive/` dibuat
- [ ] Python scripts dibuat (opsional: analyze_workspace.py, auto_index_updater.py)
- [ ] Entry log instalasi dicatat

---

## 🔧 Troubleshooting

**Q: Folder sudah ada?**
A: Skip pembuatan folder, lanjut ke file.

**Q: File sudah ada?**
A: Jangan overwrite. Tanyakan user apakah ingin reset.

**Q: Python tidak terinstall?**
A: Scripts Python bersifat opsional. AI-Agent tetap bisa berjalan tanpa scripts, hanya kurang optimal.

---

_AI-Agent Installer v1.1 | Part of Antigravity Workflows | Updated: 2025-12-22_
