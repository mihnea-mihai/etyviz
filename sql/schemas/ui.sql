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
        SELECT string_agg(dot, ' ')
        FROM ui.node
        WHERE node_id = ANY(node_ids)
    );

    edge_dots := (
        SELECT string_agg(dot, ' ')
        FROM ui.edge
        WHERE (child).node_id = ANY(node_ids)
    );

    RETURN 'digraph {concentrate=true margin=0 bgcolor="#0F0F0F" node [shape=none fontcolor="#F5F5F5"] edge [fontcolor="#F5F5F5" color="#F5F5F5"] ' || node_dots || ' ' || edge_dots || ' subgraph {rank=sink etyviz[label="etyviz 1.0.0"]}}';
END;
$$ LANGUAGE plpgsql;


    qword text, qlang_name text, flang_name text) RETURNS text AS $$
DECLARE
    child_ids int[];
    parent_ids int[];
    scope_ids int[];
    node_ids int[];
    node_dots text;
    edge_dots text;
BEGIN
    parent_ids := (
        SELECT array_agg(DISTINCT (parent).node_id)
        FROM ui.graph
        WHERE (child).word = qword
            AND (child).lang_name = qlang_name
    );

    RAISE NOTICE E'Parent ids: %', parent_ids;

    node_ids := (
        SELECT array_agg(DISTINCT (child).node_id)
        FROM ui.graph
        WHERE (parent).node_id = ANY(parent_ids)
    );

    RAISE NOTICE E'Node ids: %', node_ids;

    child_ids := (
        SELECT array_agg(DISTINCT (child).node_id)
        FROM ui.graph
        WHERE (parent).node_id = ANY(parent_ids)
            AND (child).lang_name = flang_name
    );

    RAISE NOTICE E'Child ids: %', child_ids;

    scope_ids := (
        SELECT array_agg(DISTINCT (parent).node_id)
        FROM ui.graph
        WHERE ((child).node_id = ANY(child_ids)
            OR (child).node_id = ANY(parent_ids))
            AND (parent).node_id = ANY(node_ids)
    );

    RAISE NOTICE E'Scope ids: %', scope_ids;

    node_dots := (
        SELECT string_agg(dot, ' ')
        FROM ui.node
        WHERE node_id = ANY(scope_ids)
    );
    RAISE NOTICE E'Node dots: %', node_dots;

    edge_dots := (
        SELECT string_agg(dot, ' ')
        FROM ui.edge
        WHERE (parent).node_id = ANY(scope_ids)
            AND (parent).lang_name <> flang_name
            AND (child).node_id = ANY(scope_ids)
    );
    RAISE NOTICE E'Edge dots: %', edge_dots;

    RETURN 'digraph {concentrate=true margin=0 bgcolor="#0F0F0F" node [shape=none fontcolor="#F5F5F5"] edge [fontcolor="#F5F5F5" color="#F5F5F5"] ' || node_dots || ' ' || edge_dots || '}';
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
