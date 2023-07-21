CREATE UNLOGGED TABLE staging(
    jdoc jsonb
);
ALTER TABLE staging OWNER TO etyviz;

CREATE UNLOGGED TABLE entry (
    word text,
    lang_code text,
    etym_no text,
    pos text,
    gloss text,
    templates jsonb,
    id integer GENERATED ALWAYS AS IDENTITY
);
ALTER TABLE staging OWNER TO etyviz;

CREATE RULE parse_entry AS
    ON INSERT TO staging
    DO INSTEAD (
        INSERT INTO entry (word, lang_code, etym_no, pos, gloss, templates)
        VALUES (
            NEW.jdoc ->> 'word',
            NEW.jdoc ->> 'lang_code',
            NEW.jdoc ->> 'etymology_number',
            NEW.jdoc ->> 'pos',
            NEW.jdoc #>> ARRAY['senses', '0', 'glosses', '0'],
            NEW.jdoc -> 'etymology_templates'
        )
    );

-- Run the `initdb.py` to populate `staging` from Wiktextract.