CREATE TABLE node (
    node_id     int             PRIMARY KEY REFERENCES wiktextract,
    word        varchar(256)    NOT NULL,
    lang_code   varchar(16)     NOT NULL REFERENCES lang,
    etym_no     smallint,
    pos         varchar(16),
    translit    varchar(256),
    gloss       varchar(2048)
);

CREATE UNIQUE INDEX ON node (lang_code, word, etym_no);

COMMENT ON TABLE node IS 
    'Holds all nodes possible in the etymology graph.
    Each node is a unique combination of word, lang_code, etym_no and pos';

COMMENT ON COLUMN node.node_id IS
    'ID of the entry. Originally the line number of the wiktextract dump.';
COMMENT ON COLUMN node.word IS
    'Lemma of the entry.';
COMMENT ON COLUMN node.lang_code IS
    'Wiktionary language code of the entry.
    Is used to access more data on languages from the separate table.';
COMMENT ON COLUMN node.etym_no IS
    'Etymology number of the entry.
    Used in the case of homonyms to help distinguish between forms.';
COMMENT ON COLUMN node.pos IS
    'Part of speech of the entry.';
COMMENT ON COLUMN node.translit IS
    'Transliteration of the entry in Latin alphabet.';
COMMENT ON COLUMN node.gloss IS
    'Translation of the entry in English language.
    This is the first meaning from the list of meanings.';