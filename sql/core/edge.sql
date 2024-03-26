CREATE TABLE core.edge (
    source_id   int     REFERENCES core.node,
    link_type   text    REFERENCES core.link_data,
    target_id   int     REFERENCES core.node
);

CREATE UNIQUE INDEX ON core.edge(target_id, link_type, source_id);

COMMENT ON TABLE core.edge IS
'Holds all direct links between words (nodes).
The same link type between the same two nodes cannot exist.';
