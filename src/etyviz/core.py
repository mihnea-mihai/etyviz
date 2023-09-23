"""Database wrappers."""
from typing import Union, Optional, Sequence, Mapping, Any

import psycopg


def select(
    query,
    params: Optional[Union[Sequence[Any], Mapping[str, Any]]] = None,
) -> list[tuple]:
    """Return all rows of a `SELECT` query.

    Parameters
    ----------
    query : Union[LiteralString, bytes, sql.SQL, sql.Composed]
        SQL query to be run against the database.
    params : Optional[Union[Sequence[Any], Mapping[str, Any]]], optional
        Values (parameters) to be provided to the function,
        as per psycopg, by default None

    Returns
    -------
    list[tuple]
        Query results
    """
    # pylint: disable=E1129
    with psycopg.connect("dbname=etyviz") as conn:
        with conn.cursor() as cur:
            cur.execute(query, params)
            return cur.fetchall()


def get_ascendant_graph(word: str, lang_name: str) -> str:
    return select("SELECT get_ascendant_graph(%s, %s)", [word, lang_name])[0][0]


def view_all() -> str:
    if select("SELECT count(*) FROM pre.entry")[0][0] > 10000:
        return ""
    return select("SELECT view_all()")[0][0]


def suggest_lang(part_lang: str):
    q = f"%{part_lang.lower()}%"
    return [
        row[0]
        for row in select(
            """SELECT lang_name FROM core.lang
            WHERE lower(lang_name) LIKE %s LIMIT 10""",
            [q],
        )
    ]


def suggest_word(part_word: str):
    q = f"%{part_word.lower()}%"
    return [
        row[0]
        for row in select(
            """SELECT DISTINCT word FROM core.node
            WHERE lower(word) LIKE %s LIMIT 10""",
            [q],
        )
    ]


def validate_word(word: str) -> bool:
    return bool(
        select(
            """SELECT word FROM core.node
            WHERE word = %s""",
            [word],
        )
    )


def validate_lang(lang: str) -> bool:
    return bool(
        select(
            """SELECT lang_name FROM core.lang
            WHERE lang_name = %s""",
            [lang],
        )
    )
