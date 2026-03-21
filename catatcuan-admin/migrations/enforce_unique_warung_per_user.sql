-- Enforce the app assumption that one user owns exactly one WARUNG.
-- Run manual_cleanup_duplicate_warung.sql first if duplicates already exist.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM "WARUNG"
        GROUP BY "user_id"
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Duplicate WARUNG rows still exist. Run manual_cleanup_duplicate_warung.sql before this migration.';
    END IF;
END $$;

DO $$
BEGIN
    ALTER TABLE "WARUNG"
        ADD CONSTRAINT "warung_user_id_unique" UNIQUE ("user_id");
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
