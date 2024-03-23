CREATE OR REPLACE VIEW node_friendly AS
SELECT
    node_id,
    word,
    lang_code,
    lang_name,
    etym_no,
    pos,
    substring(translit FOR 50) AS translit,
    substring(gloss FOR 100) AS gloss
FROM node
NATURAL JOIN lang;

COMMENT ON VIEW node_friendly IS
    'View for easier exploring of `node`, by truncating `translit` and `gloss`
    columns and also bringing `lang_name` from `lang` table.';