from __future__ import annotations

from etyviz.langs import Language
from etyviz import db

import time


class Word:
    def __init__(self, row) -> None:
        self.word_id = row[0]
        self.word = row[1]
        self.lang = Language.get(row[2])
        self.etym_no = row[3]
        self.pos = row[4]
        self.translit = row[5]
        self.gloss = row[6]
        self.relevancy = row[7]

    @staticmethod
    def get(qword_id) -> Word:
        q = """SELECT * FROM words WHERE node_id = %s"""
        return Word(db.execute(q, [qword_id])[0])

    @staticmethod
    def query(qlang_code, qword) -> list[Word]:
        q = """SELECT * FROM words
        WHERE word LIKE '%%' || %s || '%%' AND lang_code = %s
        ORDER BY relevancy DESC
        LIMIT 15"""
        return [Word(row) for row in db.execute(q, [qword, qlang_code])]
