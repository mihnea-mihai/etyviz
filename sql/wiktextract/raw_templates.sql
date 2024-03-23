CREATE OR REPLACE VIEW raw_templates AS
    WITH raw_template_split AS (
        SELECT
            line_no,
            jsonb_array_elements(etymology_templates) AS templates
        FROM wiktextract_parsed
    ),
    raw_args AS (
        SELECT
            line_no,
            templates ->> 'name' AS template_name,
            templates -> 'args' AS args
        FROM raw_template_split
    ),
    all_args AS (
        SELECT
            line_no,
            template_name,
            (jsonb_each_text(args)).key AS arg,
            (jsonb_each_text(args)).value AS val
        FROM raw_args
    )
    SELECT * from all_args
    WHERE val != '';