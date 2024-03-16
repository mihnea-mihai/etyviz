CREATE TABLE lang (
    lang_code   text    PRIMARY KEY,
    lang_name   text    NOT NULL,
    entry_count int     DEFAULT 0
);

CREATE INDEX ON lang (lower(lang_name));
