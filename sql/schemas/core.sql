CREATE SCHEMA core;

CREATE TABLE core.lang (
    lang_code   text        PRIMARY KEY,
    lang_name   text        NOT NULL,
    node_count  smallint
);

CREATE TABLE core.node (
    node_id     integer     PRIMARY KEY,
    word        text        NOT NULL,
    lang_code   text        REFERENCES core.lang,
    etym_no     smallint,
    pos         text,
    translit    text,
    gloss       text,
    dot         text,
    edge_count  smallint
);

CREATE TABLE core.edge (
    child_id    integer     REFERENCES core.node,
    edge_type   text        NOT NULL,
    parent_id   integer     REFERENCES core.node,
    dot         text,
    PRIMARY KEY (child_id, parent_id)
);

CREATE TABLE core.graph (
    child_id    integer     REFERENCES core.node,
    parent_id   integer     REFERENCES core.node,
    rank        smallint    NOT NULL,
    PRIMARY KEY (child_id, parent_id)
);
