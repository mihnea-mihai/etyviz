-- CREATE FUNCTION public.get_ascendant_graph(qword text, qlang_code text) RETURNS text
--     LANGUAGE sql STABLE
--     AS $$
-- WITH RECURSIVE ascendants AS (
--     SELECT w1, type, w2 FROM link
--     WHERE w1 in (
--         SELECT id FROM word
--         WHERE word = qword AND lang_code = qlang_code
--     )
--     UNION
--         SELECT link.w1, link.type, link.w2
--         FROM link
--         JOIN ascendants
--         ON ascendants.w2 = link.w1
-- ),
-- tree AS (
--     SELECT
--         w1.dot AS w1_dot,
--         w1.id AS w1_id,
--         link_type.arrow_color AS color,
--         w2.dot AS w2_dot,
--         w2.id AS w2_id
--     FROM ascendants
--     JOIN word w1 ON w1.id = ascendants.w1
--     JOIN word w2 ON w2.id = ascendants.w2
--     JOIN link_type ON link_type.type = ascendants.type
--     LIMIT 50)
-- SELECT 
--     'digraph {margin=0 bgcolor="#0F0F0F" node [shape=none fontcolor="#F5F5F5"] edge [fontcolor="#F5F5F5" color="#F5F5F5"] ' || string_agg(format('%s %s %s->%s[color="%s"]', w1_dot, w2_dot, w2_id, w1_id, color), ' ') || '}' AS link_dot
-- FROM tree;
-- $$;

-- CREATE VIEW ascendants AS
--     SELECT
--         word.id AS word_id,
--         graph.w2 AS ascendant_id
--     FROM word
--     JOIN graph ON word.id = graph.w1;

-- CREATE VIEW fancy_ascendants AS
--     SELECT
--         w1.id AS w1_id,
--         w1.word AS w1_word,
--         w1.lang_code AS w1_lang_code,
--         w2.id AS w2_id,
--         w2.word AS w2_word,
--         w2.lang_code AS w2_lang_code
--     FROM ascendants
--     JOIN word w1 ON w1.id = ascendants.word_id
--     JOIN word w2 ON w2.id = ascendants.ascendant_id;

CREATE SCHEMA ui;

CREATE VIEW ui.node AS (
    SELECT *
    FROM core.node
    JOIN core.lang USING(lang_code)
);

CREATE VIEW ui.edge AS (
    SELECT
        child,
        edge.edge_type,
        edge.dot,
        parent
    FROM core.edge
    JOIN ui.node AS child ON edge.child_id = child.node_id
    JOIN ui.node AS parent ON edge.parent_id = parent.node_id
);

CREATE VIEW ui.graph AS (
    SELECT
        child,
        graph.rank,
        parent
    FROM core.graph
    JOIN ui.node AS child ON graph.child_id = child.node_id
    JOIN ui.node AS parent ON graph.parent_id = parent.node_id
);

CREATE VIEW ui.family AS (
    SELECT
        node AS child,
        graph.rank,
        graph.parent
    FROM ui.node
    JOIN ui.graph ON (graph.child).node_id = node.node_id
);

CREATE OR REPLACE FUNCTION get_ascendant_graph(
    qword text, qlang_name text) RETURNS text AS $$
DECLARE
    node_ids int[];
    node_dots text;
    edge_dots text;
BEGIN
    node_ids := (
        SELECT array_agg(DISTINCT (parent).node_id)
        FROM ui.family
        WHERE (child).word = qword AND (child).lang_name = qlang_name
    );

    node_dots := (
        SELECT string_agg(dot, E'\n')
        FROM ui.node
        WHERE node_id = ANY(node_ids)
    );

    edge_dots := (
        SELECT string_agg(dot, E'\n')
        FROM ui.edge
        WHERE (child).node_id = ANY(node_ids)
    );

    RETURN 'digraph {margin=0 bgcolor="#0F0F0F" node [shape=none fontcolor="#F5F5F5"] edge [fontcolor="#F5F5F5" color="#F5F5F5"] ' || node_dots || E'\n' || edge_dots || '}';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_all() RETURNS text AS $$
DECLARE
    node_ids int[];
    node_dots text := (SELECT string_agg(dot, E' ') FROM ui.node);
    edge_dots text := (SELECT string_agg(dot, E' ') FROM ui.edge);
BEGIN
    RETURN 'digraph {margin=0 bgcolor="#0F0F0F" node [shape=none fontcolor="#F5F5F5"] edge [fontcolor="#F5F5F5" color="#F5F5F5"] ' || node_dots || E' ' || edge_dots || '}';
END;
$$ LANGUAGE plpgsql;