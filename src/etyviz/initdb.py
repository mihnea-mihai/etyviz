"""Import everything"""

import psycopg


def insert_lines(batch_size: int = 10000):
    """Insert everything

    Parameters
    ----------
    batch_size : int, optional
        _description_, by default 1000
    """

    # pylint: disable=E1129
    with psycopg.connect("dbname=etyviz") as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM entry")
            if result := cur.fetchone():
                offset = result[0]
            else:
                offset = 0
            print("Already processed row count:", offset)

            i = 0
            batch_i = 0

            with open("input/wiktextract.json", encoding="utf-8") as file:
                for line in file:
                    i += 1
                    if i <= offset:
                        continue
                    batch_i += 1
                    cur.execute("INSERT INTO staging VALUES(%s)", [line])
                    if batch_i >= batch_size:
                        batch_i = 0
                        conn.commit()
                        print("total rows:", i)


if __name__ == "__main__":
    insert_lines()
