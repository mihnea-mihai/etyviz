--
-- PostgreSQL database dump
--

-- Dumped from database version 14.8 (Ubuntu 14.8-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.8 (Ubuntu 14.8-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE etyviz;
--
-- Name: etyviz; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE etyviz WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'C.UTF-8';


\connect etyviz

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: conv_link_lang_code(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.conv_link_lang_code(lcode text) RETURNS text
    LANGUAGE sql STABLE
    AS $$SELECT real_code
FROM language
WHERE code = lcode$$;


--
-- Name: conv_link_word(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.conv_link_word(qword text, lcode text) RETURNS text
    LANGUAGE sql STABLE
    AS $$SELECT
	CASE
		WHEN diacr IS TRUE
			THEN unaccent(replace(qword, '*', ''))
		ELSE
			replace(qword, '*', '')
	END
FROM language
WHERE code = lcode;$$;


--
-- Name: get_ascendant_graph(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_ascendant_graph(qword text, qlang_code text) RETURNS text
    LANGUAGE sql STABLE
    AS $$
WITH RECURSIVE ascendants AS (
    SELECT w1, type, w2 FROM link
    WHERE w1 in (
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
        link_type.arrow_color AS color,
        w2.dot AS w2_dot,
        w2.id AS w2_id
    FROM ascendants
    JOIN word w1 ON w1.id = ascendants.w1
    JOIN word w2 ON w2.id = ascendants.w2
    JOIN link_type ON link_type.type = ascendants.type
    LIMIT 50)
SELECT 
    'digraph {margin=0 bgcolor="#0F0F0F" node [shape=none fontcolor="#F5F5F5"] edge [fontcolor="#F5F5F5" color="#F5F5F5"] ' || string_agg(format('%s %s %s->%s[color="%s"]', w1_dot, w2_dot, w2_id, w1_id, color), ' ') || '}' AS link_dot
FROM tree;
$$;


--
-- Name: populate_link(); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.populate_link()
    LANGUAGE sql
    AS $$INSERT INTO link (w1, type, w2)
WITH 
	raw_template AS (
		SELECT 
			entry.id AS w1,
			jsonb_array_elements(entry.templates) AS jdoc
		FROM entry
		JOIN word on entry.id = word.id
	),
	template AS (
		SELECT
			w1,
			jdoc ->> 'name' AS name,
			jdoc -> 'args' AS args
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
	),
	raw_link AS (
	SELECT
		w1,
		name AS type,
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
	)
)
SELECT
	w1,
	type,
	w2.id AS w2
FROM raw_link
JOIN word w2 ON
	w2.lang_code = conv_link_lang_code(w2_lang_code)
	AND w2.word = conv_link_word(w2_word, w2_lang_code)$$;


--
-- Name: populate_link_type(); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.populate_link_type()
    LANGUAGE sql
    AS $$INSERT INTO link_type (type)
SELECT DISTINCT type FROM link;

UPDATE link_type
	SET arrow_color = '#FCB131'
	WHERE type = ANY(ARRAY['af', 'suffix', 'affix', 'prefix', 'compound', 'com', 'suf', 'confix']);

UPDATE link_type
	SET arrow_color = '#00A651'
	WHERE type = ANY(ARRAY['inh', 'root', 'inh+']);   

UPDATE link_type
	SET arrow_color = '#EE334E'
	WHERE type = ANY(ARRAY['bor', 'bor+']);

UPDATE link_type
	SET arrow_color = '#0081C8'
	WHERE type = ANY(ARRAY['der', 'uder']);
$$;


--
-- Name: populate_word(); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.populate_word()
    LANGUAGE sql
    AS $$INSERT INTO word (word, lang_code, etym_no, pos, gloss, id)
SELECT
	word,
	lang_code,
	etym_no,
	pos,
	gloss,
	id
FROM entry
WHERE word IS NOT NULL
AND lang_code IN (SELECT code FROM language);
$$;


--
-- Name: word_dot(text, text, text, text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.word_dot(word text, lang_code text, etym_no text, pos text, gloss text, id integer) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT id::text || ' [label=<' || 
        lang_code || ' <I>(' || pos || ')</I>' ||
        '<BR/><FONT POINT-SIZE="25"><B>' || word || '</B></FONT>' ||
        '<SUP>' || COALESCE(etym_no, ' ') || '</SUP>' ||
        '<BR/><I>' || public.wrap_text(COALESCE(gloss, ' '), 30, '<BR/>'::text) || '</I>' ||
        '>]'
$$;


--
-- Name: wrap_text(text, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.wrap_text(long_text text, maxl integer DEFAULT 30, separator text DEFAULT '
'::text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT regexp_replace(
        long_text, '(.{10,' || maxl || '}) ', E'\\1' || separator, 'g'
    )
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: entry; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE public.entry (
    word text,
    lang_code text,
    etym_no text,
    pos text,
    gloss text,
    templates jsonb,
    id integer NOT NULL
);


--
-- Name: entry_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.entry ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: word; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.word (
    word text NOT NULL,
    lang_code text NOT NULL,
    etym_no text,
    pos text,
    gloss text,
    id integer NOT NULL,
    dot text GENERATED ALWAYS AS (public.word_dot(word, lang_code, etym_no, pos, gloss, id)) STORED
);


--
-- Name: raw_template; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.raw_template AS
 SELECT entry.id AS w1,
    jsonb_array_elements(entry.templates) AS jdoc
   FROM (public.entry
     JOIN public.word ON ((entry.id = word.id)));


--
-- Name: template; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.template AS
 SELECT raw_template.w1,
    (raw_template.jdoc ->> 'name'::text) AS name,
    (raw_template.jdoc -> 'args'::text) AS args
   FROM public.raw_template;


--
-- Name: expanded_template; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.expanded_template AS
 SELECT template.w1,
    template.name,
    (template.args ->>
        CASE
            WHEN (template.name = ANY (ARRAY['m'::text, 'l'::text, 'com'::text, 'compound'::text, 'suf'::text, 'suffix'::text, 'af'::text, 'affix'::text, 'prefix'::text, 'confix'::text])) THEN '1'::text
            ELSE '2'::text
        END) AS lang_code,
    (jsonb_each_text(template.args)).key AS key,
    (jsonb_each_text(template.args)).value AS value
   FROM public.template;


--
-- Name: language; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.language (
    code text NOT NULL,
    name text NOT NULL,
    diacr boolean,
    real_code text NOT NULL
);


--
-- Name: link; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.link (
    w1 integer,
    type text,
    w2 integer
);


--
-- Name: link_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.link_type (
    type text NOT NULL,
    arrow_color text
);


--
-- Name: raw_link; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.raw_link AS
 SELECT expanded_template.w1,
    expanded_template.name AS type,
    expanded_template.value AS w2_word,
    expanded_template.lang_code AS w2_lang_code
   FROM public.expanded_template
  WHERE (expanded_template.key = ANY (
        CASE
            WHEN (expanded_template.name = ANY (ARRAY['inh'::text, 'inh+'::text, 'bor'::text, 'bor+'::text, 'der'::text, 'uder'::text, 'root'::text])) THEN ARRAY['3'::text]
            WHEN (expanded_template.name = ANY (ARRAY['com'::text, 'compound'::text, 'suf'::text, 'suffix'::text, 'af'::text, 'affix'::text, 'prefix'::text, 'confix'::text])) THEN ARRAY['2'::text, '3'::text, '4'::text, '5'::text, '6'::text, '7'::text, '8'::text, '9'::text]
            ELSE ARRAY['0'::text]
        END));


--
-- Name: staging; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE public.staging (
    jdoc jsonb
);


--
-- Name: language language_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (code);


--
-- Name: link_type link_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.link_type
    ADD CONSTRAINT link_type_pkey PRIMARY KEY (type);


--
-- Name: word word_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.word
    ADD CONSTRAINT word_pkey PRIMARY KEY (id);


--
-- Name: link_type_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX link_type_type_idx ON public.link_type USING btree (type);


--
-- Name: link_w1_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX link_w1_idx ON public.link USING btree (w1);


--
-- Name: link_w2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX link_w2_idx ON public.link USING btree (w2);


--
-- Name: word_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX word_id_idx ON public.word USING btree (id);


--
-- Name: word_lang_code_word_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX word_lang_code_word_idx ON public.word USING btree (lang_code, word);


--
-- Name: staging parse_entry; Type: RULE; Schema: public; Owner: -
--

CREATE RULE parse_entry AS
    ON INSERT TO public.staging DO INSTEAD  INSERT INTO public.entry (word, lang_code, etym_no, pos, gloss, templates)
  VALUES ((new.jdoc ->> 'word'::text), (new.jdoc ->> 'lang_code'::text), (new.jdoc ->> 'etymology_number'::text), (new.jdoc ->> 'pos'::text), (new.jdoc #>> ARRAY['senses'::text, '0'::text, 'glosses'::text, '0'::text]), (new.jdoc -> 'etymology_templates'::text));


--
-- Name: language language_real_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_real_code_fkey FOREIGN KEY (real_code) REFERENCES public.language(code);


--
-- Name: link link_w1_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.link
    ADD CONSTRAINT link_w1_fkey FOREIGN KEY (w1) REFERENCES public.word(id);


--
-- Name: link link_w2_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.link
    ADD CONSTRAINT link_w2_fkey FOREIGN KEY (w2) REFERENCES public.word(id);


--
-- Name: word word_lang_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.word
    ADD CONSTRAINT word_lang_code_fkey FOREIGN KEY (lang_code) REFERENCES public.language(code);


--
-- PostgreSQL database dump complete
--

