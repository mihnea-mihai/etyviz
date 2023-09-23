"""This script provides the tools
to populate the database from the Wiktextract dump file."""
import datetime
import sys
import psycopg


def insert_lines(lite: bool = False, batch_size: int = 10000):
    """Read the Wiktextract dump and insert each line
    into the database.

    Subsequent runs will pick up from where the previous ones left
    (in case of crash or cancellation).

    Parameters
    ----------
    lite : bool, optional
        Whether to read from the lite version of the dump
        (hand-picked examples) or the full one,
        by default False
    batch_size : int, optional
        After how many inserted rows to commit the transaction,
        by default 1000
    """
    start = datetime.datetime.now()
    print("Import started at: ", start)

    if lite:
        filename = "storage/raw-wiktextract-data-lite.json"
    else:
        filename = "storage/raw-wiktextract-data.json"

    # pylint: disable=E1129
    with psycopg.connect("dbname=etyviz") as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM pre.entry")
            if result := cur.fetchone():
                offset = result[0]
            else:
                offset = 0
            print("Rows already processed:", offset)

            i = 0
            batch_i = 0

            with open(filename, encoding="utf-8") as file:
                for line in file:
                    i += 1
                    if i <= offset:
                        continue
                    batch_i += 1
                    cur.execute("INSERT INTO pre.staging (jdoc) VALUES(%s)", [line])
                    if batch_i >= batch_size:
                        batch_i = 0
                        conn.commit()
                    if i % 100000 == 0:
                        print("Total processed rows:", i)

    end = datetime.datetime.now()
    print("Import ended at: ", end)

    print("Total time: ", end - start)


if __name__ == "__main__":
    try:
        insert_lines(bool(sys.argv[1]))
    except IndexError:
        insert_lines()
