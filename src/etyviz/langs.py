from __future__ import annotations

from etyviz import db


class Language:
    def __init__(self, row) -> None:
        self.code = row[0]
        self.name = row[1]
        self.entries = row[2]

    def __repr__(self) -> str:
        return f"{self.name} language ({self.code})"

    @staticmethod
    def get(qcode) -> Language:
        q = "SELECT * FROM languages WHERE lang_code = %s"
        if res := db.execute(q, [qcode]):
            return Language(res[0])
        raise KeyError

    @staticmethod
    def query(qname) -> list[Language | None]:
        q = """SELECT * FROM languages
        WHERE lower(lang_name) LIKE '%%' || %s || '%%'
        ORDER BY entry_count DESC
        LIMIT 15"""
        if res := db.execute(q, [qname]):
            return [Language(row) for row in res]
        return []


if __name__ == "__main__":
    print(Language.query("rom"))
