CREATE TABLE core.lang (
    lang_code   text    PRIMARY KEY,
    lang_name   text    NOT NULL,
    entry_count int
);

CREATE INDEX ON core.lang (lower(lang_name));

COMMENT ON TABLE core.lang IS
    'Holds information about languages.';