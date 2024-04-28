CREATE TABLE links (
    source_id   int     REFERENCES words,
    link_type   text    REFERENCES link_data,
    target_id   int     REFERENCES words
);

CREATE UNIQUE INDEX ON links(target_id, link_type, source_id);

COMMENT ON TABLE links IS
'Holds all direct links between words (nodes).
The same link type between the same two nodes cannot exist.';
