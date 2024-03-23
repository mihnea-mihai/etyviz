CREATE SCHEMA pre;

COMMENT ON SCHEMA pre IS
'This schema contains all the necessary elements
used to populate the database.

A Python script populates `raw_dump` from all the lines in the
wiktextract dump file.

`dump` view is created from [raw_dump](/tables/raw_dump)
reading all relevant JSON paths.

[templates](/tables/templates) view is created from [dump](/tables/dump)
view and has one entry per etymology template of all rows in `dump`.

`arguments` is derived from `templates` and has one row for each argument
of each etymology template.

`raw_links` uses the data in `arguments` and the logic in `link_types`
to extract all candidate links from `line_no`s to word and language combinations.

The data flow is roughly:';

CREATE TABLE pre.raw_dump (
    line_no     int     PRIMARY KEY,
    jdoc        jsonb   NOT NULL
);

COMMENT ON TABLE pre.raw_dump IS 
    'This table holds the full wiktextract dump, in raw format.
    Each entry is a line containing the full JSON object.
    It is initially populated by a script parsing the dump file.';

COMMENT ON COLUMN pre.raw_dump.line_no IS
    'Line number of the entry in the wiktextract file.
    This is later used as the unique ID of the extracted word.';

COMMENT ON COLUMN pre.raw_dump.jdoc IS
    'Full JSON object of the entry.
    Is used to fill the other tables from the raw data.';

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
        jdoc -> 'etymology_templates' AS etymology_templates
    FROM wiktextract;

COMMENT ON VIEW pre.dump IS
    'Information extracted by parsing the JSON content.';
