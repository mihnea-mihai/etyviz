CREATE TABLE link_data (
    link_type   varchar(128)    PRIMARY KEY,
    lang_idx    varchar(16)     NOT NULL,
    word_idxs   varchar(16)[]   NOT NULL
);

CREATE OR REPLACE VIEW template_args AS (
    WITH raw_templates AS (
        SELECT
            line_no,
            jsonb_array_elements(jdoc -> 'etymology_templates') AS jdoc
        FROM
            wiktextract)
    SELECT
        line_no,
        jdoc ->> 'name' AS template_name,
        jdoc -> 'args' AS args
    FROM
        raw_templates);

CREATE OR REPLACE VIEW wiktextract_templates AS (
    SELECT template_args
    FROM wiktextract_parsed
    NATURAL JOIN template_args
);


WITH template_args_lang AS (
    SELECT
        line_no,
        template_name,
        args,
        args ->> lang_idx AS lang_code,
        word_idxs
    FROM template_args
JOIN link_data ON template_name = link_type
),
expanded_template_args AS (
    SELECT
        line_no,
        template_name,
        (jsonb_each_text(args)).key,
        (jsonb_each_text(args)).value,
        lang_code,
        word_idxs
    FROM template_args_lang
),
raw_links AS (
    SELECT
        line_no,
        template_name,
        lang_code AS target_lang,
        value AS target_word
    FROM
        expanded_template_args
    WHERE key = ANY(word_idxs)
)
SELECT
    *
FROM raw_links
JOIN node on node.word = target_word and node.lang_code = target_lang
WHERE line_no = 468686;
