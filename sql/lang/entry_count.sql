WITH lang_counts AS (
    SELECT count(*), lang_code
    FROM wiktextract_parsed
    WHERE lang_code IS NOT NULL
    GROUP BY lang_code
)
UPDATE lang
SET entry_count = count
FROM lang_counts
WHERE lang.lang_code = lang_counts.lang_code
;
