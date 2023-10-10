dropdb etyviz-test
createdb etyviz-test

export PGDATABASE=etyviz-test #so we can skip the dbname argument

psql --file=sql/schemas/core.sql
psql --file=sql/schemas/pre.sql
psql --file=sql/schemas/ui.sql
psql --file=sql/schemas/debug.sql

psql --file=sql/data/pre_language.data
psql --file=sql/data/core_language.data
psql --file=sql/data/link_type.data
psql --file=sql/data/template.data

psql --file=sql/initdb.sql

source .venv/bin/activate
python3.10 src/etyviz/parse_wiktextract.py test

psql -c 'CALL initdb();'
