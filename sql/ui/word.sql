CREATE OR REPLACE VIEW ui.word AS (
    SELECT
        node.*,
        lang_name
    FROM core.node
    NATURAL JOIN core.lang
    ORDER BY relevancy DESC
);

COMMENT ON VIEW ui.word IS
'';
