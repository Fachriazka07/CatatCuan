# Context Handoff: Master Data Sync & UI Improvements

**Date:** 2026-02-24 08:03
**Status:** IN_PROGRESS

## 🎯 Current Objective

Memperbaiki dan menyempurnakan sistem Master Kategori dan Master Satuan di CatatCuan — termasuk admin CRUD, mobile sync, popup/bottom sheet UI yang konsisten, dan styling form Insert Product.

## ✅ Completed

- [x] Admin: icon field diganti dari free-text → dropdown select (prevent emoji crash)
- [x] Admin: default icon baru = `Lainya.png`
- [x] Mobile: `_resolveIconPath` dengan validasi `_validIcons` set + fallback Lainya.png
- [x] Mobile: `_syncMasterCategories` with ID-based sync (add/edit/delete via `master_kategori_id` FK)
- [x] Mobile: `_syncMasterSatuan` with ID-based sync (same pattern via `master_satuan_id` FK)
- [x] Admin: delete = soft-delete (`is_active = false`) for both kategori and satuan
- [x] Schema: `MASTER_SATUAN` + `SATUAN_PRODUK` tables created with FK references
- [x] Schema: `master_kategori_id` FK added to `KATEGORI_PRODUK`
- [x] Admin: Master Satuan CRUD page (`master-satuan/page.tsx`) — full CRUD, soft-delete, auto-uppercase
- [x] Admin: Sidebar nav updated with Master Satuan link (Ruler icon)
- [x] Admin: Removed "Urutan" field from both Master Kategori & Satuan forms (auto-increment)
- [x] Admin: Sidebar logo changed from "CC" text to actual logo image
- [x] Mobile: `_showSatuanPicker` rewritten as DraggableScrollableSheet with DB data
- [x] Mobile: `_showAddSatuanDialog` — modern bottom sheet matching kategori style
- [x] Mobile: `_showAddKategoriDialog` — redesigned from AlertDialog to modern bottom sheet
- [x] Mobile: `_showEditKodeDialog` — modern bottom sheet with option tiles
- [x] Mobile: `_showManualEditKode` — modern bottom sheet with input
- [x] Mobile: All popups now consistent (transparent bg, rounded 24px, drag handle, icon+title header, side-by-side buttons)
- [x] Mobile: Onboarding `_seedCategories` + `_seedSatuan` with master ID references
- [x] Mobile: StokHarga card styling: Tanpa Stok 16px semibold, checkbox 20x20 rounded 5px, inputs h:60, label 14px semibold, margin 20px semibold with `.abs()`

## 🔄 In Progress

- [ ] User testing — migrations need to be run in Supabase SQL Editor
  - Migration 1: `add_master_kategori_id.sql` (backfill + dedup)
  - Migration 2: `create_satuan_tables.sql` (create tables + seed 14 default units)

## 📋 Next Steps

1. **Run migrations** in Supabase SQL Editor (user action required)
2. **Fix master data in admin**: rename "Sembako Sembako" back to "Sembako", clean up "testing"/"wok" entries
3. **Test full flow**: admin CRUD → mobile sync → picker display for both kategori and satuan
4. **Barcode scanner**: implement scan barcode feature in `_showEditKodeDialog` (TODO)
5. **Product list page** (`product-list.dart`): may need satuan display updates

## 📁 Key Files Modified

### Admin (catatcuan-admin)

- `catatcuan_schema.sql` — Added MASTER_SATUAN, SATUAN_PRODUK tables, master_kategori_id FK
- `migrations/add_master_kategori_id.sql` — FK + backfill + dedup migration
- `migrations/create_satuan_tables.sql` — Satuan tables + seed data
- `src/app/dashboard/master-kategori/page.tsx` — Icon dropdown, soft-delete, removed urutan
- `src/app/dashboard/master-satuan/page.tsx` — NEW: Full CRUD for satuan
- `src/components/app-sidebar.tsx` — Added Master Satuan nav + logo image

### Mobile (catatcuan-mobile)

- `lib/features/produk/insert_product.dart` — Major changes:
  - `_syncMasterCategories` → ID-based sync (add/edit/delete)
  - `_syncMasterSatuan` → ID-based sync (add/edit/delete)
  - `_showKategoriPicker` → DraggableScrollableSheet
  - `_showSatuanPicker` → DraggableScrollableSheet with DB data
  - `_showAddKategoriDialog` → Modern bottom sheet
  - `_showAddSatuanDialog` → Modern bottom sheet
  - `_showEditKodeDialog` → Modern bottom sheet with option tiles
  - `_showManualEditKode` → Modern bottom sheet
  - `_buildStokHargaCard` → Updated typography, checkbox, input sizing, margin calc
- `lib/features/onboarding/presentation/pages/onboarding_page.dart` — Added `_seedSatuan`, updated `_seedCategories` with master ID

## 🧠 Important Decisions

- **ID-based sync** over name-based: prevents duplicates on master edit/rename
- **Soft-delete** over hard delete: allows sync to detect deactivated categories/satuan
- **Icon heuristic abandoned**: replaced with `master_kategori_id`/`master_satuan_id` FK for reliable origin tracking
- **User-created items** (icon=Lainya.png or no master_satuan_id) are never touched by sync
- **Auto sort_order**: removed manual input from admin, auto = items.length on create

## 💡 Context Notes

- PRODUK table `satuan` column is still TEXT, not FK to SATUAN_PRODUK — may need migration later
- Existing user won't have SATUAN_PRODUK data until migration is run + sync runs on next app open
- The `_buildOptionTile` is a reusable widget for bottom sheet option cards
- `_inputDecoration` is a shared method used across all input fields for consistency
