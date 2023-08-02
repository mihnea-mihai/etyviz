SET default_statistics_target TO 1000;

CALL populate_word();

CREATE UNIQUE INDEX ON word (id);

ANALYZE;

CALL populate_raw_link();

CREATE INDEX ON word (lang_code, word);

CALL populate_link();

CREATE INDEX ON link (w1);
CREATE INDEX ON link (w2);

ANALYZE;
