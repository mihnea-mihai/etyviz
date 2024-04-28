CREATE OR REPLACE PROCEDURE pre.node_add_relevancy()
LANGUAGE SQL AS $$

WITH translations AS (
    SELECT
        line_no,
        jsonb_array_elements(jdoc -> 'translations') AS sense
    FROM pre.raw_dump
),
translation_count AS (
    SELECT line_no, count(*)
    FROM translations
    GROUP BY line_no
)
UPDATE core.node
SET relevancy = count
FROM translation_count
WHERE node.node_id = translation_count.line_no
$$;

COMMENT ON PROCEDURE pre.node_add_relevancy IS
'Populates `relevancy` column in the `node` table, grouping by `lang_code`.';
