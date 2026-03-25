-- Migration: Update cash_flow_source enum
-- Description: Add new sources for better tracking in Buku Kas

-- Note: In PostgreSQL, adding values to an enum is done with ALTER TYPE.
-- This must be run outside of a transaction block in some environments, 
-- but Supabase SQL editor usually handles it.

DO $$ BEGIN
    ALTER TYPE cash_flow_source ADD VALUE IF NOT EXISTS 'transfer';
    ALTER TYPE cash_flow_source ADD VALUE IF NOT EXISTS 'adjustment';
    ALTER TYPE cash_flow_source ADD VALUE IF NOT EXISTS 'manual_masuk';
    ALTER TYPE cash_flow_source ADD VALUE IF NOT EXISTS 'manual_keluar';
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Also ensure 'transfer' and 'adjustment' are in cash_flow_type if not already
-- though currently only 'masuk' and 'keluar' are standard.
-- If we want to keep it simple, we use masuk/keluar for type and the specific source for source.
