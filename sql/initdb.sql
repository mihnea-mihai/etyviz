CREATE OR REPLACE PROCEDURE initdb() AS $$
DECLARE
    start_time timestamp := clock_timestamp();
BEGIN
<<disable>>
    DECLARE
        start_time timestamp := clock_timestamp();
    BEGIN
        RAISE NOTICE 'DISABLING TABLE CONSTRAINTS';

        ALTER TABLE core.graph SET UNLOGGED;
        ALTER TABLE core.edge SET UNLOGGED;
        ALTER TABLE core.node SET UNLOGGED;

        ALTER TABLE core.node DROP CONSTRAINT IF EXISTS node_lang_code_fkey;
        ALTER TABLE core.edge DROP CONSTRAINT IF EXISTS edge_child_id_fkey;
        ALTER TABLE core.edge DROP CONSTRAINT IF EXISTS edge_parent_id_fkey;
        ALTER TABLE core.graph DROP CONSTRAINT IF EXISTS graph_child_id_fkey;
        ALTER TABLE core.graph DROP CONSTRAINT IF EXISTS graph_parent_id_fkey;

        COMMIT;
        RAISE NOTICE E'\tExecution time: %', 
            to_char(clock_timestamp() - start_time, 'MI:SS');
    END;

<<fill_nodes>>
    DECLARE
        start_time timestamp := clock_timestamp();
        inserted_rows integer;
    BEGIN
        RAISE NOTICE 'FILLING MAIN CORE.NODE';

        INSERT INTO core.node (node_id, word, lang_code, etym_no, pos, translit, gloss)
            SELECT entry_id, word, lang_code, etym_no, pos, translit, gloss
            FROM pre.entry
            JOIN core.lang USING (lang_code);
        GET DIAGNOSTICS inserted_rows := ROW_COUNT;
        

        RAISE NOTICE E'\tInserted % rows into core.node',
            to_char(inserted_rows, '999,999,999');
        COMMIT;
        RAISE NOTICE E'\tExecution time: %',
            to_char(clock_timestamp() - start_time, 'MI:SS');
    END;

<<fill_nodes_redirect>>
    DECLARE
        start_time timestamp := clock_timestamp();
        inserted_rows integer;
    BEGIN
        RAISE NOTICE 'FILLING CORE.NODE WITH REDIRECTS';

        INSERT INTO core.node (node_id, word, lang_code)
            WITH redirect AS (
                SELECT
                    entry_id,
                    regexp_split_to_array(title, '[:/]') AS spl
                FROM pre.entry
                WHERE title LIKE 'Reconstruction:%' AND redirect LIKE 'Reconstruction:%'
            )
            SELECT entry_id, spl[3], lang_code
            FROM redirect
            JOIN core.lang ON lang_name = spl[2];



        GET DIAGNOSTICS inserted_rows := ROW_COUNT;
        RAISE NOTICE E'\tInserted % new rows into core.node (redirect)',
            to_char(inserted_rows, '999,999,999');



        CREATE INDEX ON core.node (lang_code, word);
        COMMIT;
        RAISE NOTICE E'\tExecution time: %', 
            to_char(clock_timestamp() - start_time, 'MI:SS');
    END;

<<fill_edge>>
    DECLARE
        start_time timestamp := clock_timestamp();
        edge_count integer;
    BEGIN
        RAISE NOTICE 'FILLING CORE.EDGE';

        INSERT INTO core.edge (child_id, edge_type, parent_id)
            SELECT child.node_id, template_name, parent.node_id
            FROM pre.link
            JOIN core.node child
                ON child.node_id = link.child_id
            JOIN core.node parent
                ON parent.lang_code = parent_lang_code
                AND parent.word = parent_word
            JOIN core.lang ON parent.lang_code = lang.lang_code
        ON CONFLICT DO NOTHING;

    
        edge_count := (SELECT count(*) FROM core.edge);
        RAISE NOTICE E'\tcore.edge now has % entries', edge_count;
        VACUUM ANALYZE;
        COMMIT;
        RAISE NOTICE E'\tExecution time: %', 
            to_char(clock_timestamp() - start_time, 'MI:SS');
    END;

<<fill_edges_redirect>>
    DECLARE
        start_time timestamp := clock_timestamp();
        inserted_rows integer;
    BEGIN
        RAISE NOTICE 'FILLING CORE.EDGE WITH REDIRECTS';

        INSERT INTO core.edge (child_id, edge_type, parent_id)
            WITH redirect AS (
                SELECT
                    entry_id AS child_id,
                    (regexp_match(redirect,'Reconstruction:(.+)/(.+)$'))[2] AS parent_word,
                    (regexp_match(redirect,'Reconstruction:(.+)/(.+)$'))[1] AS parent_lang_name
                FROM pre.entry
                WHERE title ^@ 'Reconstruction:' AND redirect ^@ 'Reconstruction:'
            )
            SELECT
                child_id,
                'redirect',
                parent.node_id
            FROM redirect
            JOIN core.node AS child ON child_id = child.node_id
            JOIN core.lang ON lang.lang_name = redirect.parent_lang_name
            JOIN core.node AS parent
                ON parent.word = redirect.parent_word
                AND parent.lang_code = lang.lang_code;

        GET DIAGNOSTICS inserted_rows := ROW_COUNT;
        RAISE NOTICE E'\tInserted % new rows into core.node (redirect)',
            to_char(inserted_rows, '999,999,999');

        CREATE INDEX ON core.edge (parent_id);
        COMMIT;
        RAISE NOTICE E'\tExecution time: %', 
            to_char(clock_timestamp() - start_time, 'MI:SS');
    END;

<<purge_unlinked_nodes>>
    DECLARE
        start_time timestamp := clock_timestamp();
        node_count integer;
    BEGIN
        RAISE NOTICE 'PURGING CORE.NODE';

        node_count := (SELECT count(*) FROM core.node);
        RAISE NOTICE E'\tcore.node had % entries', node_count;

        INSERT INTO pre.staging_node
            SELECT *
            FROM core.node
            WHERE node.node_id IN (
                SELECT DISTINCT child_id FROM core.edge
                UNION
                SELECT DISTINCT parent_id FROM core.edge
            );

        TRUNCATE TABLE core.node CASCADE;

        INSERT INTO core.node
            SELECT * FROM pre.staging_node;
        
        TRUNCATE TABLE pre.staging_node;
    
        node_count := (SELECT count(*) FROM core.node);
        RAISE NOTICE E'\tcore.node now has % entries', node_count;
        ANALYZE;
        COMMIT;
        RAISE NOTICE E'\tExecution time: %', 
            to_char(clock_timestamp() - start_time, 'MI:SS');
    END;

<<purge_empty_languages>>
    DECLARE
        start_time timestamp := clock_timestamp();
        lang_count integer;
    BEGIN
        RAISE NOTICE 'PURGING CORE.LANG';

        lang_count := (SELECT count(*) FROM core.lang);
        RAISE NOTICE E'\tcore.lang had % entries', lang_count;

        DELETE FROM core.lang
            WHERE lang_code NOT IN (
                SELECT DISTINCT lang_code FROM core.node);
    
        lang_count := (SELECT count(*) FROM core.lang);
        RAISE NOTICE E'\tcore.lang now has % entries', lang_count;
        VACUUM ANALYZE;
        COMMIT;
        RAISE NOTICE E'\tExecution time: %', 
            to_char(clock_timestamp() - start_time, 'MI:SS');
    END;

<<init_graph>>
    DECLARE
        start_time timestamp := clock_timestamp();
        graph_count integer;
    BEGIN
        RAISE NOTICE 'INITIALISING CORE.GRAPH';

        INSERT INTO core.graph (child_id, parent_id, rank)
            SELECT DISTINCT
                node_id AS child_id,
                node_id AS parent_id,
                0 AS rank
            FROM core.node;
        CREATE INDEX ON core.graph (parent_id);

        graph_count := (SELECT count(*) FROM core.graph);
        RAISE NOTICE E'\tcore.graph now has % entries', graph_count;
        VACUUM ANALYZE;
        COMMIT;
        RAISE NOTICE E'\tExecution time: %', 
            to_char(clock_timestamp() - start_time, 'MI:SS');
    END;

<<increase_graph>>
    DECLARE
        start_time timestamp := clock_timestamp();
        graph_count integer;
        section_start_time timestamp;
        affected_rows integer;
        rnk smallint := 0;
    BEGIN
        RAISE NOTICE 'INCREASING CORE.GRAPH';
        LOOP

            section_start_time := clock_timestamp();
            graph_count := (SELECT count(*) FROM core.graph);
            RAISE NOTICE E'\trank: %', rnk;
            RAISE NOTICE E'\t\tcore.graph had % entries', graph_count;
            INSERT INTO core.graph(child_id, parent_id, rank)
                SELECT
                    graph.child_id,
                    edge.parent_id,
                    rnk + 1 AS rank
                FROM core.graph
                JOIN core.edge ON graph.parent_id = edge.child_id
                WHERE rank = rnk
                GROUP BY graph.child_id, edge.parent_id
            ON CONFLICT (child_id, parent_id)
                DO UPDATE SET rank = excluded.rank;

            GET DIAGNOSTICS affected_rows := ROW_COUNT;
            RAISE NOTICE E'\t\tAffected rows: %',
                to_char(affected_rows, '999,999,999');
            IF affected_rows < 1 OR rnk > 10 THEN
                EXIT;
            END IF;
            rnk := rnk + 1;
            VACUUM ANALYZE;
            COMMIT;
            RAISE NOTICE E'\t\tTime elapsed: %', 
                to_char(clock_timestamp() - section_start_time, 'MI:SS');
        END LOOP;

        graph_count := (SELECT count(*) FROM core.graph);
        RAISE NOTICE E'\tcore.graph now has % entries', graph_count;

        COMMIT;
        RAISE NOTICE E'\tExecution time: %', 
            to_char(clock_timestamp() - start_time, 'MI:SS');
    END;

<<purge_edges_transitive_reduction>>
    DECLARE
        start_time timestamp := clock_timestamp();
        edge_count integer;
    BEGIN
        RAISE NOTICE 'PURGING CORE.EDGE';

        edge_count := (SELECT count(*) FROM core.edge);
        RAISE NOTICE E'\tcore.edge had % entries', edge_count;

        DELETE FROM core.edge
            USING core.graph
            WHERE graph.rank > 1
                AND graph.child_id = edge.child_id
                AND graph.parent_id = edge.parent_id;
    
        edge_count := (SELECT count(*) FROM core.edge);
        RAISE NOTICE E'\tcore.edge now has % entries', edge_count;
        ANALYZE;
        COMMIT;
        RAISE NOTICE E'\tExecution time: %', clock_timestamp() - start_time;
    END;

<<update_node_dot>>
    DECLARE
        start_time timestamp := clock_timestamp();
    BEGIN
        RAISE NOTICE 'UPDATING DOT ON CORE.NODE';

        

        UPDATE core.node
            SET dot = pre.word_dot(
                node_id, word, lang.lang_name, etym_no, pos, translit, gloss)
            FROM core.lang
            WHERE core.node.lang_code = core.lang.lang_code;
        COMMIT;
        RAISE NOTICE E'\tExecution time: %', clock_timestamp() - start_time;
    END;

<<update_edge_dot>>
    DECLARE
        start_time timestamp := clock_timestamp();
    BEGIN
        RAISE NOTICE 'UPDATING DOT ON CORE.EDGE';

        UPDATE core.edge
            SET dot = format('%s->%s[color="%s"]',
                parent_id, child_id, arrow_color)
            FROM pre.link_type
            WHERE edge_type = link_type;
        COMMIT;
        RAISE NOTICE E'\tExecution time: %', clock_timestamp() - start_time;
    END;

<<enable>>
    DECLARE
        start_time timestamp := clock_timestamp();
    BEGIN
        RAISE NOTICE 'ENABLING TABLE CONSTRAINTS';
    
        ALTER TABLE core.node ADD CONSTRAINT node_lang_code_fkey
            FOREIGN KEY (lang_code) REFERENCES core.lang;
        ALTER TABLE core.edge ADD CONSTRAINT edge_child_id_fkey
            FOREIGN KEY (child_id) REFERENCES core.node;
        ALTER TABLE core.edge ADD CONSTRAINT edge_parent_id_fkey
            FOREIGN KEY (parent_id) REFERENCES core.node;
        ALTER TABLE core.graph ADD CONSTRAINT graph_child_id_fkey
            FOREIGN KEY (child_id) REFERENCES core.node;
        ALTER TABLE core.graph ADD CONSTRAINT graph_parent_id_fkey
            FOREIGN KEY (parent_id) REFERENCES core.node;

        ALTER TABLE core.node SET LOGGED;
        ALTER TABLE core.edge SET LOGGED;
        ALTER TABLE core.graph SET LOGGED;
        COMMIT;
        RAISE NOTICE E'\tExecution time: %', clock_timestamp() - start_time;
    END;

RAISE NOTICE E'\tTotal execution time: %', clock_timestamp() - start_time;
ANALYZE;
END;
$$ LANGUAGE plpgsql;
