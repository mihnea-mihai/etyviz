CREATE TABLE words (
    node_id     int         PRIMARY KEY,
    word        text        NOT NULL,
    lang_code   text        NOT NULL REFERENCES languages,
    etym_no     smallint,
    pos         text,
    translit    text,
    gloss       text,
    relevancy   int
);

CREATE UNIQUE INDEX ON words (lang_code, word, etym_no);

COMMENT ON TABLE words IS 
    'Holds all nodes possible in the etymology graph.
    Each node is a unique combination of word, lang_code, etym_no and pos';

COMMENT ON COLUMN words.node_id IS
    'ID of the entry. Originally the line number of the wiktextract dump.';
COMMENT ON COLUMN words.word IS
    'Lemma of the entry.';
COMMENT ON COLUMN words.lang_code IS
    'Wiktionary language code of the entry.
    Is used to access more data on languages from the separate table.';
COMMENT ON COLUMN words.etym_no IS
    'Etymology number of the entry.
    Used in the case of homonyms to help distinguish between forms.';
COMMENT ON COLUMN words.pos IS
    'Part of speech of the entry.';
COMMENT ON COLUMN words.translit IS
    'Transliteration of the entry in Latin alphabet.';
COMMENT ON COLUMN words.gloss IS
    'Translation of the entry in English language.
    This is the first meaning from the list of meanings.';

CREATE OR REPLACE PROCEDURE words_insert()
LANGUAGE SQL AS $$

INSERT INTO words (
    node_id, word, lang_code, etym_no, pos, translit, gloss
)
SELECT
    line_no,
    jdoc ->> 'word',
    jdoc ->> 'lang_code',
    (jdoc ->> 'etymology_number')::int,
    jdoc ->> 'pos',
    jsonb_path_query_first (
        jdoc, '($.forms[*] ? (@.tags[0] == "romanization")).form'
    ) #>> '{}',
    jdoc #>> ARRAY['senses', '0', 'glosses', '0']
FROM wiktextract
WHERE jdoc ? 'word'
ON CONFLICT DO NOTHING;

$$;

COMMENT ON PROCEDURE words_insert IS
'Populates the `node` table with information extracted from the dump.';
