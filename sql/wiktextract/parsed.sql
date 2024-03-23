CREATE OR REPLACE VIEW wiktextract_parsed AS
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
        jdoc -> 'etymology_templates' AS etymology_templates
    FROM wiktextract;

COMMENT ON VIEW wiktextract_parsed IS
    'Information extracted by parsing the JSON content.';