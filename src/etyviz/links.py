from __future__ import annotations

from etyviz.words import Word
from etyviz import db


class Link:
    def __init__(self, row) -> None:
        self.source = Word.get(row[0])
        self.type = row[1]
        self.target = Word.get(row[2])

    @staticmethod
    def query(qsource=None, qtarget=None) -> list[Link]:
        q = """SELECT * FROM links
        WHERE source_id = %s OR target_id = %s
        LIMIT 15"""
        return [Link(row) for row in db.execute(q, [qsource, qtarget])]


if __name__ == "__main__":
    print(Link.query(136575))
