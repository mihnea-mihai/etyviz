CREATE OR REPLACE FUNCTION lang_get_by_name(IN qlang text)
RETURNS SETOF text
LANGUAGE SQL
AS $$

SELECT lang_name
FROM lang
WHERE lower(lang_name) LIKE '%' || qlang || '%'
ORDER BY entry_count DESC
LIMIT 10;

$$;

COMMENT ON FUNCTION lang_get_by_name(text) IS   
    'Returns the first 10 languages matching the wildcard search.';