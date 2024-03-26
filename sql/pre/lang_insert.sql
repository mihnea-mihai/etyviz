CREATE OR REPLACE PROCEDURE pre.lang_insert()
LANGUAGE SQL AS $$

WITH lang_stats AS (
    SELECT lang_code, lang_name, count(*)
    FROM pre.dump
    WHERE lang_code IS NOT NULL
    GROUP BY lang_code, lang_name
    ORDER BY count(*) DESC
)
INSERT INTO core.lang (
    lang_code, lang_name
)
SELECT lang_code, lang_name
FROM lang_stats
ON CONFLICT DO NOTHING;

$$;

COMMENT ON PROCEDURE pre.lang_insert IS
'Populates `lang_code` and `lang_name` columns in the `lang` table.
If multiple language names are found for the same language code,
the most used is saved in the table.';
