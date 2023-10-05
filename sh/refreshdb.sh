pg_dump --dbname=etyviz --data-only --table=pre.entry --format=custom --file='storage/entry.dump'
source sh/initdb.sh
pg_restore storage/entry.dump
psql -c 'CALL initdb();'
