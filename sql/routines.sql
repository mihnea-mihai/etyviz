CREATE EXTENSION "unaccent";

CREATE RULE parse_entry AS
    ON INSERT TO staging
    DO INSTEAD (
        INSERT INTO entry (word, lang_code, etym_no, pos, gloss, templates)
        VALUES (
            NEW.jdoc ->> 'word',
            NEW.jdoc ->> 'lang_code',
            NEW.jdoc ->> 'etymology_number',
            NEW.jdoc ->> 'pos',
            NEW.jdoc #>> ARRAY['senses', '0', 'glosses', '0'],
            NEW.jdoc -> 'etymology_templates'
        )
    );

CREATE PROCEDURE populate_word() LANGUAGE 'sql' AS $BODY$
    INSERT INTO word (word, lang_code, etym_no, pos, gloss, id)
    WITH agg AS (
        SELECT
            word,
            lang_code,
            array_agg(etym_no ORDER BY etym_no NULLS FIRST) AS etym_no_agg,
            array_agg(pos ORDER BY etym_no NULLS FIRST) AS pos_agg,
            array_agg(gloss ORDER BY etym_no NULLS FIRST) AS gloss_agg,
            array_agg(id ORDER BY etym_no NULLS FIRST) AS id_agg
        FROM entry
        WHERE word IS NOT NULL
        GROUP BY lang_code, word
    )
    SELECT
        word,
        lang_code,
        etym_no_agg[1] AS etym_no,
        pos_agg[1] AS pos,
        gloss_agg[1] AS gloss,
        id_agg[1] AS id
    FROM agg;
$BODY$;

CREATE PROCEDURE populate_raw_link() LANGUAGE 'sql' AS $BODY$
    INSERT INTO raw_link
        (w1, type, w2_word, w2_lang_code)
    WITH 
        raw_template AS (
            SELECT 
                entry.id AS w1,
                jsonb_array_elements(entry.templates) AS jdoc
            FROM entry
            JOIN word ON entry.id = word.id
        ),
        template AS (
            SELECT
                w1,
                jdoc ->> 'name',
                jdoc -> 'args'
            FROM raw_template
        ),
        expanded AS (
            SELECT
                w1,
                name,
                args ->> (
                    CASE 
                        WHEN name = ANY(ARRAY['m', 'l', 'com', 'compound', 'suf', 'suffix', 'af', 'affix', 'prefix', 'confix'])
                            THEN
                                '1'
                        ELSE
                            '2'
                    END
                    ) AS lang_code,
                (jsonb_each_text(args)).key AS key,
                (jsonb_each_text(args)).value AS value
            FROM template
        )
    SELECT
        w1,
        name,
        value AS w2_word,
        lang_code AS w2_lang_code
    FROM expanded
    WHERE key = ANY(
        CASE
            -- WHEN name = ANY(ARRAY['m', 'l'])
            --     THEN ARRAY['2']
            WHEN name = ANY(ARRAY['inh', 'inh+', 'bor', 'bor+', 'der', 'uder', 'root'])
                THEN ARRAY['3']
            WHEN name = ANY(ARRAY['com', 'compound', 'suf', 'suffix', 'af', 'affix', 'prefix', 'confix'])
                THEN ARRAY['2', '3', '4', '5', '6', '7', '8', '9']
            ELSE
                ARRAY['0']
        END
    );
    UPDATE raw_link
        SET w2_word = replace(w2_word, '*', ''),
            w2_word_unaccented = replace(unaccent(w2_word), '*', '');
$BODY$;

CREATE PROCEDURE populate_link() LANGUAGE 'sql' AS $BODY$
    INSERT INTO link (w1, type, w2)
        SELECT
            w1,
            type,
            w2.id AS w2
        FROM raw_link
        JOIN word w2 ON
            w2.lang_code = raw_link.w2_lang_code
            AND w2.word = raw_link.w2_word_unaccented
        UNION
        SELECT
            w1,
            type,
            w2.id AS w2
        FROM raw_link
        JOIN word w2 ON
            w2.lang_code = raw_link.w2_lang_code
            AND w2.word = raw_link.w2_word;
$BODY$;

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
