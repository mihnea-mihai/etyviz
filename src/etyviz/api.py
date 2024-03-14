"""Functions to be used by the API."""

from etyviz import db


def get_language(language_name: str) -> list:
    rows = db.execute_file("sql/lang_query.sql", [language_name])
    return [row[0] for row in rows]
