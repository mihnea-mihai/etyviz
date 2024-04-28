--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2 (Ubuntu 16.2-1.pgdg22.04+1)
-- Dumped by pg_dump version 16.2 (Ubuntu 16.2-1.pgdg22.04+1)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: words; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.words (
    node_id integer NOT NULL,
    word text NOT NULL,
    lang_code text NOT NULL,
    etym_no smallint,
    pos text,
    translit text,
    gloss text,
    relevancy integer
);


--
-- Name: TABLE words; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.words IS 'Holds all nodes possible in the etymology graph.
    Each node is a unique combination of word, lang_code, etym_no and pos';


--
-- Name: COLUMN words.node_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.words.node_id IS 'ID of the entry. Originally the line number of the wiktextract dump.';


--
-- Name: COLUMN words.word; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.words.word IS 'Lemma of the entry.';


--
-- Name: COLUMN words.lang_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.words.lang_code IS 'Wiktionary language code of the entry.
    Is used to access more data on languages from the separate table.';


--
-- Name: COLUMN words.etym_no; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.words.etym_no IS 'Etymology number of the entry.
    Used in the case of homonyms to help distinguish between forms.';


--
-- Name: COLUMN words.pos; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.words.pos IS 'Part of speech of the entry.';


--
-- Name: COLUMN words.translit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.words.translit IS 'Transliteration of the entry in Latin alphabet.';


--
-- Name: COLUMN words.gloss; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.words.gloss IS 'Translation of the entry in English language.
    This is the first meaning from the list of meanings.';


--
-- Name: get_word(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_word(qword text, qlang_code text) RETURNS SETOF public.words
    LANGUAGE sql
    AS $$SELECT *
FROM words
WHERE lang_code = qlang_code
AND word like qword || '%'
ORDER BY relevancy DESC, word
LIMIT 15;$$;


--
-- Name: get_word_link_count(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_word_link_count(qid integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $$SELECT count(*)
FROM links
WHERE source_id = qid
OR target_id = qid$$;


--
-- Name: languages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.languages (
    lang_code text NOT NULL,
    lang_name text NOT NULL,
    entry_count integer
);


--
-- Name: TABLE languages; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.languages IS 'Holds information and statistics about languages.';


--
-- Name: COLUMN languages.lang_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.languages.lang_code IS 'Wiktionary language code.';


--
-- Name: COLUMN languages.lang_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.languages.lang_name IS 'Language name. If several names are found for the same code,
the most used one is saved.';


--
-- Name: COLUMN languages.entry_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.languages.entry_count IS 'Number of Wiktionary entries of the language.';


--
-- Name: language_get_by_name(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.language_get_by_name(qlang text) RETURNS SETOF public.languages
    LANGUAGE sql STABLE
    AS $$

SELECT *
FROM languages
WHERE lower(lang_name) LIKE '%' || lower(qlang) || '%'
OR lower(lang_code) LIKE '%' || lower(qlang) || '%'
ORDER BY entry_count DESC
LIMIT 15;

$$;


--
-- Name: FUNCTION language_get_by_name(qlang text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.language_get_by_name(qlang text) IS 'Returns the first 10 languages matching the wildcard search.';


--
-- Name: languages_insert(); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.languages_insert()
    LANGUAGE sql
    AS $$

WITH langs AS (
    SELECT
        jdoc ->> 'lang_code' AS lang_code,
        jdoc ->> 'lang' AS lang_name
    FROM wiktextract
    WHERE jdoc ? 'lang_code'
),
lang_stats AS (
    SELECT lang_code, lang_name, count(*)
    FROM langs
    GROUP BY lang_code, lang_name
    ORDER BY count(*) DESC
)
INSERT INTO languages (
    lang_code, lang_name
)
SELECT lang_code, lang_name
FROM lang_stats
ON CONFLICT DO NOTHING;

$$;


--
-- Name: PROCEDURE languages_insert(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON PROCEDURE public.languages_insert() IS 'Populates `lang_code` and `lang_name` columns in the `lang` table.
If multiple language names are found for the same language code,
the most used is saved in the table.';


--
-- Name: languages_update_count(); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.languages_update_count()
    LANGUAGE sql
    AS $$

WITH lang_counts AS (
    SELECT count(*), jdoc ->> 'lang_code' AS lang_code
    FROM wiktextract
    WHERE jdoc ? 'lang_code'
    GROUP BY lang_code
)
UPDATE languages
SET entry_count = count
FROM lang_counts
WHERE languages.lang_code = lang_counts.lang_code;

$$;


--
-- Name: PROCEDURE languages_update_count(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON PROCEDURE public.languages_update_count() IS 'Populates `entry_count` column in the `lang` table, grouping by `lang_code`.';


--
-- Name: links_insert_simple(); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.links_insert_simple()
    LANGUAGE sql
    AS $$


INSERT INTO links (
    source_id, link_type, target_id
)
WITH raw_templates AS (
    SELECT
        line_no,
        jsonb_array_elements(jdoc -> 'etymology_templates') AS templ
    FROM wiktextract
),
templates AS (
    SELECT
        line_no,
        templ ->> 'name' AS template_name,
        templ -> 'args' AS args
    FROM raw_templates
),
arguments_lang AS (
    SELECT
        line_no,
        template_name,
        args,
        args ->> lang_idx AS lang_code,
        word_idxs
    FROM templates
    JOIN link_data ON template_name = link_type
),
expanded_arguments AS (
    SELECT
        line_no,
        template_name,
        (jsonb_each_text(args)).key,
        (jsonb_each_text(args)).value,
        lang_code,
        word_idxs
    FROM arguments_lang
),
raw_links AS (
    SELECT
        line_no,
        template_name,
        lang_code AS target_lang,
        value AS target_word
    FROM
        expanded_arguments
    WHERE key = ANY(word_idxs)
)
SELECT line_no, template_name, target_word.node_id
FROM raw_links
JOIN words AS source_word
ON source_word.node_id = raw_links.line_no
JOIN words AS target_word
ON target_word.word = raw_links.target_word
    AND target_word.lang_code = raw_links.target_lang
    AND target_word.etym_no IS NULL
ON CONFLICT DO NOTHING;

$$;


--
-- Name: PROCEDURE links_insert_simple(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON PROCEDURE public.links_insert_simple() IS 'Populates the `edge` table with information extracted from `pre.raw_links`.
Only takes into account entries not needing disambiguation.';


--
-- Name: words_insert(); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.words_insert()
    LANGUAGE sql
    AS $_$

INSERT INTO words (
    node_id, word, lang_code, etym_no, pos, translit, gloss
)
SELECT
    line_no,
    jdoc ->> 'word',
    jdoc ->> 'lang_code',
    (jdoc ->> 'etymology_number')::int,
    jdoc ->> 'pos',
    jsonb_path_query_first (
        jdoc, '($.forms[*] ? (@.tags[0] == "romanization")).form'
    ) #>> '{}',
    jdoc #>> ARRAY['senses', '0', 'glosses', '0']
FROM wiktextract
WHERE jdoc ? 'word'
ON CONFLICT DO NOTHING;

$_$;


--
-- Name: PROCEDURE words_insert(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON PROCEDURE public.words_insert() IS 'Populates the `node` table with information extracted from the dump.';


--
-- Name: words_update_relevancy(); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.words_update_relevancy()
    LANGUAGE sql
    AS $$WITH source_link_count AS (
	SELECT source_id, count(*)
	FROM links
	GROUP BY source_id
),
target_link_count AS (
	SELECT target_id, count(*)
	FROM links
	GROUP BY target_id
),
words_stats AS (
	SELECT node_id, coalesce(src.count, 0) + coalesce(trg.count, 0) AS total_count
	FROM words
	LEFT OUTER JOIN source_link_count AS src ON source_id = node_id
	LEFT OUTER JOIN target_link_count AS trg ON target_id = node_id
)
UPDATE words
SET relevancy = total_count
FROM words_stats
WHERE words_stats.node_id = words.node_id;$$;


--
-- Name: link_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.link_data (
    link_type character varying(128) NOT NULL,
    lang_idx character varying(16) NOT NULL,
    word_idxs character varying(16)[] NOT NULL
);


--
-- Name: TABLE link_data; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.link_data IS 'Holds data for each link type.';


--
-- Name: links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.links (
    source_id integer,
    link_type text,
    target_id integer
);


--
-- Name: TABLE links; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.links IS 'Holds all direct links between words (nodes).
The same link type between the same two nodes cannot exist.';


--
-- Name: wiktextract; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wiktextract (
    line_no integer NOT NULL,
    jdoc jsonb NOT NULL
);


--
-- Name: TABLE wiktextract; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.wiktextract IS 'This table holds the full wiktextract dump, in raw format.
Each entry is a line containing the full JSON object.
It is initially populated by a script parsing the dump file.';


--
-- Name: COLUMN wiktextract.line_no; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wiktextract.line_no IS 'Line number of the entry in the wiktextract file.
This is later used as the unique ID of the extracted word.';


--
-- Name: COLUMN wiktextract.jdoc; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wiktextract.jdoc IS 'Full JSON object of the entry.
It is used to fill the other tables from the raw data.';


--
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (lang_code);


--
-- Name: link_data link_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.link_data
    ADD CONSTRAINT link_data_pkey PRIMARY KEY (link_type);


--
-- Name: wiktextract wiktextract_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiktextract
    ADD CONSTRAINT wiktextract_pkey PRIMARY KEY (line_no);


--
-- Name: words words_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.words
    ADD CONSTRAINT words_pkey PRIMARY KEY (node_id);


--
-- Name: languages_lower_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX languages_lower_idx ON public.languages USING btree (lower(lang_name));


--
-- Name: links_target_id_link_type_source_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX links_target_id_link_type_source_id_idx ON public.links USING btree (target_id, link_type, source_id);


--
-- Name: words_lang_code_word_etym_no_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX words_lang_code_word_etym_no_idx ON public.words USING btree (lang_code, word, etym_no);


--
-- Name: links links_link_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_link_type_fkey FOREIGN KEY (link_type) REFERENCES public.link_data(link_type);


--
-- Name: links links_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.words(node_id);


--
-- Name: links links_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.words(node_id);


--
-- Name: words words_lang_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.words
    ADD CONSTRAINT words_lang_code_fkey FOREIGN KEY (lang_code) REFERENCES public.languages(lang_code);


--
-- PostgreSQL database dump complete
--

