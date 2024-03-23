CREATE TABLE edge (
    source_id   int     REFERENCES node,
    link_type   text,
    target_id   int     REFERENCES node
);

CREATE UNIQUE INDEX ON edge(target_id, link_type, source_id);

COMMENT ON TABLE edge IS
    'Holds all direct links between words (nodes).';
