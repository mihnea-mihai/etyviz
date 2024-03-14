WITH node_letters AS (
    SELECT
        string_to_table(lower(word), NULL) AS letter,
        lang_code
    FROM node
),
node_counts AS (
    SELECT
        count(*) AS node_count,
        lang_code
    FROM node_letters
    WHERE letter IS NOT NFD NORMALIZED
    GROUP BY lang_code
),
edge_letters AS (
    SELECT
        string_to_table(lower(target_word), NULL) AS letter,
        target_lang
    FROM edge
),
edge_counts AS (
    SELECT
        count(*) AS edge_count,
        target_lang
    FROM edge_letters
    WHERE letter IS NOT NFD NORMALIZED
    GROUP BY target_lang
)
SELECT
    node_counts.node_count,
    node_counts.lang_code,
    edge_counts.edge_count
FROM node_counts
JOIN edge_counts ON node_counts.lang_code = edge_counts.target_lang
LIMIT 100;