CREATE OR REPLACE PROCEDURE node_insert()
LANGUAGE SQL AS $$

INSERT INTO node (
    node_id, word, lang_code, etym_no, pos, translit, gloss
)
SELECT line_no, word, lang_code, etym_no, pos, translit, gloss
FROM wiktextract_parsed
WHERE word IS NOT NULL
ON CONFLICT DO NOTHING;

$$;

COMMENT ON PROCEDURE node_insert IS
    'Populates the `node` table with information extracted from the dump.';