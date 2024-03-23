CREATE OR REPLACE PROCEDURE lang_insert()
LANGUAGE SQL AS $$

WITH lang_stats AS (
    SELECT lang_code, lang_name, count(*)
    FROM wiktextract_parsed
    WHERE lang_code IS NOT NULL
    GROUP BY lang_code, lang_name
    ORDER BY count(*) DESC
)
INSERT INTO lang (
    lang_code, lang_name
)
SELECT lang_code, lang_name
FROM lang_stats
ON CONFLICT DO NOTHING;

$$;

COMMENT ON PROCEDURE lang_insert IS
    'Populates `lang_code` and `lang_name` columns in the `lang` table.
    If multiple language names are found for the same language code,
    the most used is saved in the table.';