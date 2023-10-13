"""Database wrappers."""
from typing import Union, Optional, Sequence, Mapping, Any

import graphviz
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


def get_ascendant_graph_dot(word: str, lang_name: str) -> str:
    return select("SELECT ui.get_ascendant_graph(%s, %s)", [word, lang_name])[0][0]


def get_related_graph_dot(word: str, lang_name: str, filter_lang_name: str) -> str:
    return select(
        "SELECT ui.get_related_graph(%s, %s, %s)", [word, lang_name, filter_lang_name]
    )[0][0]


def view_all() -> str:
    if select("SELECT count(*) FROM pre.entry")[0][0] > 10000:
        return ""
    return select("SELECT view_all()")[0][0]


def generate_file_from_dot(dot: str, filename: str) -> None:
    gv = graphviz.Source(dot)
    gv.unflatten(1000, True, chain=10).render(outfile=filename)


def generate_showcase() -> None:
    sdir = "graphs/showcase"
    generate_file_from_dot(
        get_related_graph_dot("pleca", "Romanian", "Romanian"),
        f"{sdir}/Plec cu plosca exploatând un fiasco.pdf",
    )
    generate_file_from_dot(
        get_related_graph_dot("Angst", "German", "Romanian"),
        f"{sdir}/Îngustimea angoasei.pdf",
    )
    generate_file_from_dot(
        get_related_graph_dot("sobor", "Romanian", "Aromanian"),
        f"{sdir}/Furând furtuna friptă și ferită de sobor.pdf",
    )
    generate_file_from_dot(
        get_related_graph_dot("câmp", "Romanian", "Romanian"),
        f"{sdir}/Campionatul campestru al șampaniei câmpenești.pdf",
    )


if __name__ == "__main__":
    generate_showcase()
