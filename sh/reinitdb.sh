if [[ ! $1 ]]
then
    pg_dump --dbname=etyviz --data-only --table=pre.entry --format=custom --file='storage/entry.dump'
else
    echo Ignoring pre.entry
fi

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

if [[ ! $2 ]]
then
    echo Keep Wiktextract
else
    wget https://kaikki.org/dictionary/raw-wiktextract-data.json.gz
    gzip --decompress --force raw-wiktextract-data.json.gz
    mv raw-wiktextract-data.json storage/
fi

if [ ! $1 ]
then
    pg_restore storage/entry.dump
else
    source .venv/bin/activate
    python3.10 src/etyviz/parse_wiktextract.py
fi

psql -c 'CALL initdb();'
