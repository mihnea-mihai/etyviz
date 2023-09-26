CREATE SCHEMA IF NOT EXISTS pre;
-- Insert in DB from Wiktextract

    CREATE UNLOGGED TABLE IF NOT EXISTS pre.staging(
            jdoc jsonb
        );

    CREATE UNLOGGED TABLE IF NOT EXISTS pre.entry(
        entry_id    integer     GENERATED ALWAYS AS IDENTITY,
        word        text,
        lang_code   text,
        etym_no     smallint,
        pos         text,
        translit    text,
        gloss       text,
        templates   jsonb,
        form_of     text,
        title       text,
        redirect    text
    );

    CREATE OR REPLACE RULE parse_entry AS 
    ON INSERT TO pre.staging DO INSTEAD
        INSERT INTO pre.entry(
            word,
            lang_code,
            etym_no,
            pos,
            translit,
            gloss,
            templates,
            form_of,
            title,
            redirect)
        VALUES (
            new.jdoc ->> 'word',
            new.jdoc ->> 'lang_code',
            (new.jdoc ->> 'etymology_number')::smallint,
            new.jdoc ->> 'pos',
            jsonb_path_query_first(new.jdoc, '($.forms[*] ? (@.tags[0] == "romanization")).form') #>> '{}',
            new.jdoc #>> ARRAY['senses', '0', 'glosses', '0'],
            new.jdoc -> 'etymology_templates',
            new.jdoc #>> ARRAY['senses', '0', 'form_of', '0', 'word'],
            new.jdoc ->> 'title',
            new.jdoc ->> 'redirect');

-- Update nodes dot

CREATE OR REPLACE FUNCTION pre.wrap_text(
            long_text text,
            maxl integer,
            separator text) RETURNS text LANGUAGE SQL IMMUTABLE AS $$ SELECT
                regexp_replace(
                    long_text,
                    '(.{10,' || maxl || '}) ', E'\\1' || separator,
                    'g'
                );
        $$;

        CREATE OR REPLACE FUNCTION pre.dot_escape(str text)
            RETURNS text LANGUAGE SQL IMMUTABLE AS $$
                SELECT replace(replace(
                    replace(replace(str, '"', '""'), '&', ''),
                    '>', ''), '<', '');
        $$;

        CREATE OR REPLACE FUNCTION pre.word_dot (
            node_id integer,
            word text,
            lang text,
            etym_no smallint,
            pos text,
            translit text,
            gloss text) RETURNS text LANGUAGE SQL IMMUTABLE AS $$ SELECT
            concat(node_id, ' [label=<', lang, ' <I>(', pos, ')</I>',
                '<BR/><FONT POINT-SIZE="25"><B>', word, '</B></FONT>',
                '<SUP>', COALESCE(etym_no::text, ' '), '</SUP>', '<BR/><I>',
                pre.dot_escape(pre.wrap_text(COALESCE(gloss, ' '), 30, '<BR/>')
                ), '</I>', '>]');
        $$;

-- Create edges

    CREATE VIEW pre.template_elements AS
        SELECT
            entry_id AS child_id,
            jsonb_array_elements(templates) AS jdoc
        FROM pre.entry;

    CREATE VIEW pre.template_arguments AS
        SELECT
            child_id,
            jdoc ->> 'name' AS template_name,
            jdoc -> 'args' AS args
        FROM pre.template_elements;

    CREATE UNLOGGED TABLE pre.template(
        template_name   text    PRIMARY KEY,
        lang_code_idx   text,
        word_idx_arr    text[]
    );

    CREATE VIEW pre.expanded_template AS
        SELECT
            child_id,
            template_name,
            args ->> template.lang_code_idx AS lang_code,
            (jsonb_each_text(args)).key AS key,
            (jsonb_each_text(args)).value AS value
        FROM pre.template_arguments
        JOIN pre.template USING (template_name);

    CREATE FUNCTION pre.add_dash (value text, name text, key text)
        RETURNS text LANGUAGE SQL IMMUTABLE AS $$ SELECT
            CASE WHEN (name = 'suffix' OR name = 'suf') AND key = '3'
                THEN concat('-', value)
            WHEN (name = 'prefix' OR name = 'pre') AND key = '2'
                THEN concat(value, '-')
            ELSE
                value
            END 
        $$;

    CREATE VIEW pre.raw_link AS
        SELECT
            child_id,
            template_name,
            pre.add_dash(value, template_name, key) AS parent_word,
            lang_code AS parent_lang_code
        FROM pre.expanded_template
        JOIN pre.template USING (template_name)
        WHERE key = ANY(template.word_idx_arr)
        UNION
        SELECT
            entry_id AS child_id,
            'form_of' AS edge_type,
            form_of AS parent_word,
            lang_code AS parent_lang_code
        FROM pre.entry;

    CREATE UNLOGGED TABLE pre.lang (
        lang_code   text    PRIMARY KEY,
        diacr       bool,
        real_code   text
    );

    CREATE EXTENSION unaccent;

    CREATE FUNCTION pre.sanitize_word (word text, diacr bool)
        RETURNS text LANGUAGE SQL IMMUTABLE AS $$ SELECT     
            CASE WHEN diacr IS TRUE
                THEN unaccent(replace(word, '*', ''))
            ELSE
                replace(word, '*', '')
            END 
        $$;

    CREATE VIEW pre.link AS
        SELECT
            child_id,
            template_name,
            pre.sanitize_word(parent_word, lang.diacr) AS parent_word,
            lang.real_code AS parent_lang_code
        FROM pre.raw_link
        JOIN pre.lang ON raw_link.parent_lang_code = lang.lang_code;

-- Purge unlinked nodes

    CREATE UNLOGGED TABLE pre.staging_node (LIKE core.node EXCLUDING ALL);

-- Update edge dot

    CREATE TABLE pre.link_type (
        link_type text PRIMARY KEY,
        arrow_color text
    );
