CREATE TABLE link_data (
    link_type   varchar(128)    PRIMARY KEY,
    lang_idx    varchar(16)     NOT NULL,
    word_idxs   varchar(16)[]   NOT NULL
);

COMMENT ON TABLE link_data IS
'Holds data for each link type.';

INSERT INTO link_data (link_type, lang_idx, word_idxs) VALUES
('inh', '2', ARRAY['3']),
('m', '1', ARRAY['2']),
('cog', '1', ARRAY['2']),
('der', '2', ARRAY['3']),
('bor', '2', ARRAY['3']),
('af', '1', ARRAY['2', '3', '4', '5', '6', '7', '8', '9']),
('suffix', '1', ARRAY['2', '3', '4', '5', '6', '7', '8', '9']),
('affix', '1', ARRAY['2', '3', '4', '5', '6', '7', '8', '9']),
('bor+', '2', ARRAY['3']),
('prefix', '1', ARRAY['2', '3', '4', '5', '6', '7', '8', '9']),
('compound', '1', ARRAY['2', '3', '4', '5', '6', '7', '8', '9']),
('inh+', '2', ARRAY['3']),
('l', '1', ARRAY['2']),
('root', '2', ARRAY['3']),
('com', '1', ARRAY['2', '3', '4', '5', '6', '7', '8', '9']),
('uder', '2', ARRAY['3'])
;

CREATE TABLE links (
    source_id   int     REFERENCES words,
    link_type   text    REFERENCES link_data,
    target_id   int     REFERENCES words
);

CREATE UNIQUE INDEX ON links(target_id, link_type, source_id);

COMMENT ON TABLE links IS
'Holds all direct links between words (nodes).
The same link type between the same two nodes cannot exist.';


CREATE OR REPLACE PROCEDURE links_insert_simple()
LANGUAGE SQL AS $$


INSERT INTO links (
    source_id, link_type, target_id
)
WITH raw_templates AS (
    SELECT
        line_no,
        jsonb_array_elements(jdoc -> 'etymology_templates') AS templ
    FROM wiktextract
),
templates AS (
    SELECT
        line_no,
        templ ->> 'name' AS template_name,
        templ -> 'args' AS args
    FROM raw_templates
),
arguments_lang AS (
    SELECT
        line_no,
        template_name,
        args,
        args ->> lang_idx AS lang_code,
        word_idxs
    FROM templates
    JOIN link_data ON template_name = link_type
),
expanded_arguments AS (
    SELECT
        line_no,
        template_name,
        (jsonb_each_text(args)).key,
        (jsonb_each_text(args)).value,
        lang_code,
        word_idxs
    FROM arguments_lang
),
raw_links AS (
    SELECT
        line_no,
        template_name,
        lang_code AS target_lang,
        value AS target_word
    FROM
        expanded_arguments
    WHERE key = ANY(word_idxs)
)
SELECT line_no, template_name, target_word.node_id
FROM raw_links
JOIN words AS source_word
ON source_word.node_id = raw_links.line_no
JOIN words AS target_word
ON target_word.word = raw_links.target_word
    AND target_word.lang_code = raw_links.target_lang
    AND target_word.etym_no IS NULL
ON CONFLICT DO NOTHING;

$$;

COMMENT ON PROCEDURE links_insert_simple IS
'Populates the `edge` table with information extracted from `pre.raw_links`.
Only takes into account entries not needing disambiguation.';
