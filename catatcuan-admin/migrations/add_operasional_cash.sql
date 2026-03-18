-- Migration: Add Operasional Cash to WARUNG
-- Description: Split cash into Warung and Operasional

-- 1. Add column to WARUNG
ALTER TABLE "WARUNG" 
ADD COLUMN IF NOT EXISTS "uang_kas_operasional" DECIMAL(15, 2) DEFAULT 0.00;

-- 2. Rename existing uang_kas to clarify (using alias in code is safer than renaming if other services use it)
-- For now, we will treat the existing 'uang_kas' column in the code as 'Uang Warung' 
-- and the new column as 'Uang Operasional'.

COMMENT ON COLUMN "WARUNG"."uang_kas_operasional" IS 'Cash balance for operational expenses.';

-- 3. Update BUKU_KAS to track source
ALTER TABLE "BUKU_KAS"
ADD COLUMN IF NOT EXISTS "sumber_kas" TEXT DEFAULT 'warung'; -- 'warung' or 'operasional'

COMMENT ON COLUMN "BUKU_KAS"."sumber_kas" IS 'Source of the cash flow: warung or operasional.';
