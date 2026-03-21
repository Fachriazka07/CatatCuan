-- Manual cleanup for duplicate WARUNG rows caused by repeated onboarding submits.
-- Keep the newest WARUNG per user_id and delete older duplicates.
-- WARNING: deleting duplicate WARUNG rows will also delete child rows through ON DELETE CASCADE.

WITH ranked_warung AS (
    SELECT
        "id",
        "user_id",
        ROW_NUMBER() OVER (
            PARTITION BY "user_id"
            ORDER BY "created_at" DESC, "id" DESC
        ) AS rn
    FROM "WARUNG"
)
DELETE FROM "WARUNG" AS w
USING ranked_warung AS r
WHERE w."id" = r."id"
  AND r.rn > 1;
