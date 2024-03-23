CREATE TABLE lang (
    lang_code   text    PRIMARY KEY,
    lang_name   text    NOT NULL,
    entry_count int     NOT NULL
);

CREATE INDEX ON lang (lower(lang_name));

COMMENT ON TABLE lang IS
    'Holds information about languages.';