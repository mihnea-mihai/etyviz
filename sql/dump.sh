# ON SOURCE

pg_dump etyviz --format=c --no-unlogged-table-data > etyviz.dump

# ON TARGET

pg_restore etyviz.dump --create --clean --if-exists --no-owner

pg_restore etyviz.dump --create --clean --if-exists --no-owner --schema-only