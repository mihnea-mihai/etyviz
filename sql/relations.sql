CREATE UNLOGGED TABLE staging(
    jdoc jsonb
);

CREATE UNLOGGED TABLE entry (
    word text,
    lang_code text,
    etym_no text,
    pos text,
    gloss text,
    templates jsonb,
    id integer GENERATED ALWAYS AS IDENTITY
);

CREATE TABLE word (
    word text NOT NULL,
    lang_code text NOT NULL,
    etym_no text,
    pos text,
    gloss text,
    id integer PRIMARY KEY,
    dot text GENERATED ALWAYS AS (
        id::text || ' [label=<' || 
        lang_code || ' <I>(' || pos || ')</I>' ||
        '<BR/><FONT POINT-SIZE="25"><B>' || word || '</B></FONT>' ||
        '<SUP>' || COALESCE(etym_no, ' ') || '</SUP>' ||
        '<BR/><I>' || COALESCE(gloss, ' ') || '</I>' ||
        '>]'
    ) STORED
);

CREATE UNLOGGED TABLE raw_link (
    w1 integer REFERENCES word,
    type text,
    w2_word text,
    w2_lang_code text,
	w2_word_unaccented text
);

CREATE TABLE link (
    w1 integer REFERENCES word,
    type text,
    w2 integer REFERENCES word
);
