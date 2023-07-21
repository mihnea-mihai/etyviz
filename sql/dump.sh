# ON SOURCE

pg_dump etyviz -s > etyviz.sql
pg_dump etyviz -a -t word -t link > etyviz.data

# ON TARGET

psql -f etyviz.sql etyviz
psql -f etyviz.data etyviz

