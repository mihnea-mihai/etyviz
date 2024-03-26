CREATE OR REPLACE VIEW pre.templates AS
    WITH raw_templates AS (
        SELECT
            line_no,
            jsonb_array_elements(etymology_templates) AS templates
        FROM pre.dump
    )
    SELECT
        line_no,
        templates ->> 'name' AS template_name,
        templates -> 'args' AS args
    FROM raw_templates;

COMMENT ON VIEW pre.templates IS
'2 - Each row is an element of the `etymology_template` node.';
