# For local development

## Export

Export the full schema and config data

```sh
# Full schema
pg_dump etyviz --schema-only --no-owner --create --clean > sql/etyviz.sql

# Config data
pg_dump etyviz --no-owner --table=language --table=link_type > sql/config.dump
```

## Import

```sh
# Import the exports above
export PGDATABASE=etyviz

psql --file=sql/etyviz.sql
psql --file=sql/config.dump

# Populate data locally
wget https://kaikki.org/dictionary/raw-wiktextract-data.json.gz
gzip --decompress --force raw-wiktextract-data.json.gz
mv raw-wiktextract-data.json sql/
source .venv/bin/activate
python3.11 src/etyviz/initdb.py

psql --file=sql/flow.sql
```

# For deployment

## Export

Export a compressed format, omitting data in staging tables.

```sh
pg_dump etyviz --format=c --no-unlogged-table-data > sql/etyviz.dump
```

## Import

```sh
pg_restore etyviz.dump --create --clean --if-exists --no-owner
```
