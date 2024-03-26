CREATE OR REPLACE VIEW pre.raw_links AS (
    WITH arguments_lang AS (
        SELECT
            line_no,
            template_name,
            args,
            args ->> lang_idx AS lang_code,
            word_idxs
        FROM pre.templates
    JOIN core.link_data ON template_name = link_type
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
    )
    SELECT
        line_no,
        template_name,
        lang_code AS target_lang,
        value AS target_word
    FROM
        expanded_arguments
    WHERE key = ANY(word_idxs)
);

COMMENT ON VIEW pre.raw_links IS
'3 - Holds all tentative links from an entry (with ID as `line_no`)
to candidate other entries (defined by `word` and `lang_code`).';
