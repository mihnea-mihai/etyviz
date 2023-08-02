dropdb etyviz
createdb etyviz

source .venv/bin/activate

export PGDATABASE=etyviz

psql --file=sql/relations.sql

psql --file=sql/routines.sql

python3.11 src/etyviz/initdb.py

psql --file=sql/flow.sql
