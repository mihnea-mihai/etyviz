"""Database wrappers."""
from typing import LiteralString, Union, Optional, Sequence, Mapping, Any

import psycopg
from psycopg import sql


def select(
    query: Union[LiteralString, bytes, sql.SQL, sql.Composed],
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


def get_ascendant_graph(word: str, lang_code: str) -> str:
    return select("SELECT get_ascendant_graph(%s, %s)", [word, lang_code])[0][0]
