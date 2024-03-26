CREATE TABLE core.link_data (
    link_type   varchar(128)    PRIMARY KEY,
    lang_idx    varchar(16)     NOT NULL,
    word_idxs   varchar(16)[]   NOT NULL
);

COMMENT ON TABLE core.link_data IS
'Holds data for each link type.';

INSERT INTO core.link_data (link_type, lang_idx, word_idxs) VALUES
('inh', '2', ARRAY['3']),
('m', '1', ARRAY['2']),
('cog', '1', ARRAY['2']),
('der', '2', ARRAY['3']),
('bor', '2', ARRAY['3']),
('af', '1', ARRAY['2', '3', '4', '5', '6', '7', '8', '9']),
('suffix', '1', ARRAY['2', '3', '4', '5', '6', '7', '8', '9']),
('affix', '1', ARRAY['2', '3', '4', '5', '6', '7', '8', '9']),
('bor+', '2', ARRAY['3']),
('prefix', '1', ARRAY['2', '3', '4', '5', '6', '7', '8', '9']),
('compound', '1', ARRAY['2', '3', '4', '5', '6', '7', '8', '9']),
('inh+', '2', ARRAY['3']),
('l', '1', ARRAY['2']),
('root', '2', ARRAY['3']),
('com', '1', ARRAY['2', '3', '4', '5', '6', '7', '8', '9']),
('uder', '2', ARRAY['3'])
;