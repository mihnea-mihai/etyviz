WITH unique_codes AS (
    SELECT DISTINCT lang_code, lang_name
    FROM wiktextract_parsed
    WHERE lang_code IS NOT NULL
),
ambiguous_codes AS (
    SELECT lang_code, count(*)
    FROM unique_codes
    GROUP BY lang_code
    HAVING count(*) > 1
)
SELECT unique_codes.lang_code, lang_name
FROM unique_codes
JOIN ambiguous_codes
ON unique_codes.lang_code = ambiguous_codes.lang_code
ORDER BY lang_code;
