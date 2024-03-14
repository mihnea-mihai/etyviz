rm --force raw-wiktextract-data.json.gz
wget https://kaikki.org/dictionary/raw-wiktextract-data.json.gz
gzip --decompress raw-wiktextract-data.json.gz
mv raw-wiktextract-data.json data/wiktextract.jsonl
