CREATE TABLE languages (
    lang_code   text    PRIMARY KEY,
    lang_name   text    NOT NULL,
    entry_count int
);

CREATE INDEX ON languages (lower(lang_name));

COMMENT ON TABLE languages IS
    'Holds information and statistics about languages.';

COMMENT ON COLUMN languages.lang_code IS
'Wiktionary language code.';

COMMENT ON COLUMN languages.lang_name IS
'Language name. If several names are found for the same code,
the most used one is saved.';

COMMENT ON COLUMN languages.entry_count IS
'Number of Wiktionary entries of the language.';

CREATE OR REPLACE PROCEDURE languages_insert()
LANGUAGE SQL AS $$

WITH langs AS (
    SELECT
        jdoc ->> 'lang_code' AS lang_code,
        jdoc ->> 'lang' AS lang_name
    FROM wiktextract
    WHERE jdoc ? 'lang_code'
),
lang_stats AS (
    SELECT lang_code, lang_name, count(*)
    FROM langs
    GROUP BY lang_code, lang_name
    ORDER BY count(*) DESC
)
INSERT INTO languages (
    lang_code, lang_name
)
SELECT lang_code, lang_name
FROM lang_stats
ON CONFLICT DO NOTHING;

$$;

COMMENT ON PROCEDURE languages_insert IS
'Populates `lang_code` and `lang_name` columns in the `lang` table.
If multiple language names are found for the same language code,
the most used is saved in the table.';

CREATE OR REPLACE PROCEDURE languages_update_count()
LANGUAGE SQL AS $$

WITH lang_counts AS (
    SELECT count(*), jdoc ->> 'lang_code' AS lang_code
    FROM wiktextract
    WHERE jdoc ? 'lang_code'
    GROUP BY lang_code
)
UPDATE languages
SET entry_count = count
FROM lang_counts
WHERE languages.lang_code = lang_counts.lang_code;

$$;

COMMENT ON PROCEDURE languages_update_count IS
'Populates `entry_count` column in the `lang` table, grouping by `lang_code`.';

CREATE OR REPLACE FUNCTION language_get_by_name(IN qlang text)
RETURNS SETOF languages
LANGUAGE SQL
AS $$

SELECT *
FROM languages
WHERE lower(lang_name) LIKE '%' || lower(qlang) || '%'
OR lower(lang_code) LIKE '%' || lower(qlang) || '%'
ORDER BY entry_count DESC
LIMIT 15;

$$;

COMMENT ON FUNCTION language_get_by_name(text) IS   
'Returns the first 10 languages matching the wildcard search.';
