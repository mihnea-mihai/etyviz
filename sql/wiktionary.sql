CREATE TABLE wiktextract (
    line_no     int     PRIMARY KEY,
    jdoc        jsonb   NOT NULL
);

COMMENT ON TABLE wiktextract IS 
'This table holds the full wiktextract dump, in raw format.
Each entry is a line containing the full JSON object.
It is initially populated by a script parsing the dump file.';

COMMENT ON COLUMN wiktextract.line_no IS
'Line number of the entry in the wiktextract file.
This is later used as the unique ID of the extracted word.';

COMMENT ON COLUMN wiktextract.jdoc IS
'Full JSON object of the entry.
It is used to fill the other tables from the raw data.';
