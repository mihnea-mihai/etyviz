CREATE SCHEMA debug;

CREATE OR REPLACE VIEW debug.edge AS (
    SELECT
        (child).word AS child_word,
        (child).lang_code AS child_lang,
        (child).node_id AS child_id,
        edge_type,
        (parent).word AS parent_word,
        (parent).lang_code AS parent_lang,
        (parent).node_id AS parent_id
    FROM ui.edge
);

CREATE OR REPLACE VIEW debug.graph AS (
    SELECT
        (child).word AS child_word,
        (child).lang_code AS child_lang,
        (child).node_id AS child_id,
        rank,
        (parent).word AS parent_word,
        (parent).lang_code AS parent_lang,
        (parent).node_id AS parent_id
    FROM ui.graph
);
