source sh/initdb.sh
source .venv/bin/activate
python3.10 src/etyviz/parse_wiktextract.py
psql -c 'CALL initdb();'
