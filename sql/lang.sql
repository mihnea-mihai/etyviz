DROP TABLE IF EXISTS lang;

CREATE TABLE lang (
    lang_code   text    PRIMARY KEY,
    lang_name   text    NOT NULL,
    entry_count int
);

INSERT INTO lang (
    lang_code, lang_name
)
SELECT
    jdoc->>'lang_code',
    jdoc->>'lang'
FROM wiktextract
WHERE jdoc->>'lang_code' IS NOT NULL
ON CONFLICT DO NOTHING;

CREATE INDEX ON lang (lower(lang_name));


WITH lang_counts AS (
    SELECT count(*), lang_code
    FROM node
    GROUP BY lang_code
)
UPDATE lang
SET entry_count = count
FROM lang_counts
WHERE lang.lang_code = lang_counts.lang_code;

WITH letters AS (
    SELECT
        string_to_table(lower(word), NULL) AS letter
    FROM node
    WHERE lang_code = 'en'
)
SELECT
    count(*),
    letter
FROM letters
GROUP BY letter
ORDER BY count DESC;

WITH node_letters AS (
    SELECT
        string_to_table(lower(word), NULL) AS letter,
        lang_code
    FROM node
),
edge_letters AS (
    SELECT
        string_to_table(lower(target_word), NULL) AS letter,
        target_lang
    FROM edge
),
node_ratio AS (
    SELECT
        count(*),
        lang_code
    FROM node_letters
    WHERE NOT (letter = ANY(ARRAY['a', 'b', 'c', 'd', 'e', 'f', 'i',
        'g', 'h', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
        'x', 'y', 'z', 'u', 'v', ' ', '-', '/', '*', 'w', ',', '.', '_',
        '''', '1', '2', '3', '4', '5', '6', '7', '8', '9' ,'0', '+', ')', '(']))
    GROUP BY lang_code
),
edge_ratio AS (
    SELECT
        count(*),
        target_lang
    FROM edge_letters
    WHERE NOT (letter = ANY(ARRAY['a', 'b', 'c', 'd', 'e', 'f', 'i',
        'g', 'h', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
        'x', 'y', 'z', 'u', 'v', ' ', '-', '/', '*', 'w', ',', '.', '_',
        '''', '1', '2', '3', '4', '5', '6', '7', '8', '9' ,'0', '+', ')', '(']))
    GROUP BY target_lang
)
SELECT
    node_ratio.count AS node_count,
    node_ratio.lang_code,
    edge_ratio.count AS edge_count,
    edge_ratio.count / node_ratio.count AS chance
FROM node_ratio
JOIN edge_ratio
ON node_ratio.lang_code = edge_ratio.target_lang
WHERE edge_ratio.count / node_ratio.count >= 1
ORDER BY edge_ratio.count / node_ratio.count DESC;

