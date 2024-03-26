CREATE OR REPLACE PROCEDURE pre.lang_count_insert()
LANGUAGE SQL AS $$

WITH lang_counts AS (
    SELECT count(*), lang_code
    FROM pre.dump
    WHERE lang_code IS NOT NULL
    GROUP BY lang_code
)
UPDATE core.lang
SET entry_count = count
FROM lang_counts
WHERE lang.lang_code = lang_counts.lang_code;

$$;

COMMENT ON PROCEDURE pre.lang_count_insert IS
'Populates `entry_count` column in the `lang` table, grouping by `lang_code`.';
