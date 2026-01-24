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
