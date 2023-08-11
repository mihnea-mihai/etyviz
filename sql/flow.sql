SET default_statistics_target TO 1000;
CALL populate_word();
ANALYZE;
CALL populate_raw_link();
CALL populate_link();
CALL populate_link_type();
ANALYZE;
