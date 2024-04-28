CREATE OR REPLACE VIEW pre.dump AS
    SELECT
        line_no,
        jdoc ->> 'word' AS word,
        jdoc ->> 'lang_code' AS lang_code,
        jdoc ->> 'lang' AS lang_name,
        (jdoc ->> 'etymology_number')::smallint AS etym_no,
        jdoc ->> 'pos' AS pos,
        jsonb_path_query_first (
            jdoc, '($.forms[*] ? (@.tags[0] == "romanization")).form'
        ) #>> '{}' AS translit,
        jdoc #>> ARRAY['senses', '0', 'glosses', '0'] AS gloss,
        jdoc #>> ARRAY['senses', '0', 'form_of', '0', 'word'] AS form_of,
        jdoc ->> 'title' AS title,
        jdoc ->> 'redirect' AS redirect,
        jdoc -> 'etymology_templates' AS etymology_templates,
        char_length(jdoc ->> 'senses') AS relevancy
    FROM pre.raw_dump;

COMMENT ON VIEW pre.dump IS
'1 - Derived from `raw_dump` by parsing the relevant JSON paths.';
