CREATE OR REPLACE VIEW ui.link AS (
    SELECT
        source_node.word AS source_word,
        source_node.lang_code AS source_lang,
        source_node.lang_name AS source_lang_name,
        substring(source_node.gloss FOR 50) AS source_gloss,
        edge.link_type,
        target_node.word AS target_word,
        target_node.lang_code AS target_lang,
        target_node.lang_name AS target_lang_name,
        substring(target_node.gloss FOR 50) AS target_gloss
    FROM core.edge
    JOIN ui.word AS source_node
    ON source_node.node_id = edge.source_id
    JOIN ui.word AS target_node
    ON target_node.node_id = edge.target_id
);

COMMENT ON VIEW ui.link IS
'';
