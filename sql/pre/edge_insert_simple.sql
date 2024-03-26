CREATE OR REPLACE PROCEDURE pre.edge_insert_simple()
LANGUAGE SQL AS $$

INSERT INTO core.edge (
    source_id, link_type, target_id
)
    SELECT line_no, template_name, target_node.node_id
    FROM pre.raw_links
    JOIN core.node AS source_node
    ON source_node.node_id = raw_links.line_no
    JOIN core.node AS target_node
    ON target_node.word = raw_links.target_word
        AND target_node.lang_code = raw_links.target_lang
        AND target_node.etym_no IS NULL
ON CONFLICT DO NOTHING;

$$;

COMMENT ON PROCEDURE pre.edge_insert_simple IS
'Populates the `edge` table with information extracted from `pre.raw_links`.
Only takes into account entries not needing disambiguation.';
