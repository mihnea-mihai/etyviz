import logging
import psycopg

import etyviz.logs


def execute_file(path: str, params=None):
    """Execute SQL commands located in a given file.

    Parameters
    ----------
    path : str
        Filepath.
    """
    with open(path, mode="rb") as file:
        # pylint: disable=not-context-manager
        with psycopg.connect("dbname=etyviz") as conn:
            with conn.cursor() as cur:
                cur.execute(file.read(), params)
                return cur.fetchall()


def file_to_db() -> None:
    """Migrate the information in the dump file in the DB.
    Each row becomes an entry in the `wiktextract` table.
    """
    # execute_file("sql/wiktextract.sql")

    with open("data/wiktextract.jsonl", encoding="utf-8", mode="r") as file:
        i = 1
        # pylint: disable=not-context-manager
        with psycopg.connect("dbname=etyviz") as conn:
            with conn.cursor() as cur:
                for line in file:
                    cur.execute("INSERT INTO wiktextract VALUES (%s, %s)", [i, line])
                    if i % 100000 == 0:
                        conn.commit()
                        logging.debug("Wrote line %i to DB", i)
                    i += 1


def wiki_to_node() -> None:
    """Populate the `node` table from the JSON information
    in the `wiki` table.
    """
    pass


if __name__ == "__main__":
    file_to_db()
    # execute_file("sql/lang.sql")
