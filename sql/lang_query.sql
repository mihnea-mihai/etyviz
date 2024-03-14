SELECT lang_name
FROM lang
WHERE lower(lang_name) LIKE '%%' || %s || '%%'
ORDER BY entry_count DESC
LIMIT 10;