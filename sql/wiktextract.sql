DROP TABLE IF EXISTS wiktextract;

CREATE TABLE wiktextract (
    entry_id    int     PRIMARY KEY,
    jdoc        jsonb   NOT NULL
);

DROP VIEW IF EXISTS wiktextract_parsed;

CREATE VIEW wiktextract_parsed AS
    SELECT
        entry_id,
        jdoc ->> 'word' AS word,
        jdoc ->> 'lang_code' AS lang_code,
        (jdoc ->> 'etymology_number')::smallint AS etym_no,
        jdoc ->> 'pos' AS pos,
        jsonb_path_query_first (
            jdoc, '($.forms[*] ? (@.tags[0] == "romanization")).form'
        ) #>> '{}' AS translit,
        jdoc #>> ARRAY['senses', '0', 'glosses', '0'] AS gloss,
        jdoc #>> ARRAY['senses', '0', 'form_of', '0', 'word'] AS form_of,
        jdoc ->> 'title' AS title,
        jdoc ->> 'redirect' AS redirect
    FROM wiktextract;