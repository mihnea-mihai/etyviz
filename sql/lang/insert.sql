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
ON CONFLICT DO NOTHING
;
