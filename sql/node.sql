DROP TABLE IF EXISTS node;

CREATE TABLE node (
    node_id     int     PRIMARY KEY,
    word        text,
    lang_code   text    REFERENCES lang,
    etym_no     smallint,
    pos         text,
    translit    text,
    gloss       text,
    CONSTRAINT node_node_id_fkey
        FOREIGN KEY (node_id) REFERENCES wiktextract
);

CREATE UNIQUE INDEX ON node (lang_code, word, etym_no);

