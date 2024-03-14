DROP TABLE IF EXISTS edge;

CREATE TABLE edge(
  entry_id int,
  template_name text,
  target_word text,
  target_lang text
);

INSERT INTO edge(
  entry_id,
  template_name,
  target_word,
  target_lang)
WITH templates AS (
  SELECT
    entry_id,
    jsonb_array_elements(jdoc -> 'etymology_templates') AS jdoc
  FROM
    wiktextract),
arg_templates AS (
  SELECT
    entry_id,
    jdoc ->> 'name' AS template_name,
    jdoc -> 'args' AS args
  FROM
    templates),
  expanded_templates AS (
    SELECT
      entry_id,
      template_name,
      args ->> '1' AS target_lang,
(jsonb_each_text(args)).value AS target_word,
(jsonb_each_text(args)).key AS arg
    FROM
      arg_templates
)
  SELECT
    entry_id,
    template_name,
    args ->> '1' AS target_lang,
    args ->> '2' AS target_word
  FROM
    arg_templates
  WHERE
    template_name = ANY (ARRAY['m', 'cog', 'l'])
  UNION
  SELECT
    entry_id,
    template_name,
    args ->> '2' AS target_lang,
    args ->> '3' AS target_word
  FROM
    arg_templates
  WHERE
    template_name = ANY (ARRAY['inh', 'root', 'inh+', 'bor',
      'bor+', 'der', 'uder'])
  UNION
  SELECT
    entry_id,
    template_name,
    target_lang,
    target_word
  FROM
    expanded_templates
  WHERE
    template_name = ANY (ARRAY['affix', 'af', 'com', 'suffix',
      'suf', 'prefix', 'confix', 'compound'])
    AND arg = ANY (ARRAY['2', '3', '4', '5']);

CREATE OR REPLACE VIEW links AS
    SELECT
        word AS source_word,
        lang_code AS source_lang,
        substring(gloss FOR 100) AS source_gloss,
        template_name AS link_type,
        target_word,
        target_lang
    FROM
        node
    JOIN edge ON node.node_id = edge.entry_id;