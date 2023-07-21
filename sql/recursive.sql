CREATE FUNCTION get_ascendant_graph(
	qword text,
	qlang_code text)
    RETURNS text
    LANGUAGE 'sql'
    STABLE
AS $BODY$
WITH RECURSIVE ascendants AS (
    SELECT w1, type, w2 FROM link
    WHERE w1 = (
    SELECT id FROM word
    WHERE word = qword AND lang_code = qlang_code
)
    UNION
        SELECT link.w1, link.type, link.w2
        FROM link
        JOIN ascendants
        ON ascendants.w2 = link.w1
),
tree AS (
    SELECT
        w1.dot AS w1_dot,
        w1.id AS w1_id,
        ascendants.type AS link_type,
        w2.dot AS w2_dot,
        w2.id AS w2_id
    FROM ascendants
    JOIN word w1 ON w1.id = ascendants.w1
    JOIN word w2 ON w2.id = ascendants.w2
    LIMIT 50)
SELECT 
    'digraph {margin=0 bgcolor="#0F0F0F" node [shape=none fontcolor="#F5F5F5"] edge [fontcolor="#F5F5F5" color="#F5F5F5"] ' || string_agg(format('%s %s %s->%s[label="%s"]', w1_dot, w2_dot, w2_id, w1_id, link_type), ' ') || '}' AS link_dot
FROM tree;
$BODY$;

ALTER FUNCTION get_ascendant_graph(text, text)
    OWNER TO etyviz;
