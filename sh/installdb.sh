rm etyviz.dump
wget https://github.com/mihnea-mihai/etyviz/releases/latest/download/etyviz.dump
pg_restore etyviz.dump --dbname=postgres --create --clean --if-exists --no-owner --verbose