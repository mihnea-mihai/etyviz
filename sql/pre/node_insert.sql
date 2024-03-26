CREATE OR REPLACE PROCEDURE pre.node_insert()
LANGUAGE SQL AS $$

INSERT INTO core.node (
    node_id, word, lang_code, etym_no, pos, translit, gloss
)
SELECT line_no, word, lang_code, etym_no, pos, translit, gloss
FROM pre.dump
WHERE word IS NOT NULL
ON CONFLICT DO NOTHING;

$$;

COMMENT ON PROCEDURE pre.node_insert IS
'Populates the `node` table with information extracted from the dump.';
