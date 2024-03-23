CREATE TABLE raw_dump (
    line_no     int     PRIMARY KEY,
    jdoc        jsonb   NOT NULL
);

COMMENT ON TABLE raw_dump IS 
    'This table holds the full wiktextract dump, in raw format.
    Each entry is a line containing the full JSON object.
    This table will be ignored from deployment, as it takes 15GB of storage.';

COMMENT ON COLUMN raw_dump.line_no IS
    'Line number of the entry in the wiktextract file.
    This is later used as the unique ID of the extracted word.';

COMMENT ON COLUMN raw_dump.jdoc IS
    'Full JSON object of the entry.
    Is used to fill the other tables from the raw data.';
