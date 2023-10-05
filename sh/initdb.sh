dropdb etyviz
createdb etyviz

export PGDATABASE=etyviz #so we can skip the dbname argument

psql --file=sql/schemas/core.sql
psql --file=sql/schemas/pre.sql
psql --file=sql/schemas/ui.sql
psql --file=sql/schemas/debug.sql

psql --file=sql/data/pre_language.data
psql --file=sql/data/core_language.data
psql --file=sql/data/link_type.data
psql --file=sql/data/template.data

psql --file=sql/initdb.sql




