"""Public API"""

from etyviz.core import select


def suggest_lang(part_lang: str = ""):
    """Return a list of filtered languages based on input letters."""
    q = f"%{part_lang.lower()}%"
    return [
        row[0]
        for row in select(
            """SELECT lang_name FROM core.lang
            WHERE lower(lang_name) LIKE %s
            ORDER BY node_count DESC LIMIT 10""",
            [q],
        )
    ]


print(suggest_lang("romd"))


def suggest_word(lang_name: str, part_word: str):
    q = f"%{part_word.lower()}%"
    return [
        row[0]
        for row in select(
            """SELECT DISTINCT word FROM core.node
            JOIN core.lang USING (lang_code)
            WHERE lang_name = %s
                AND word LIKE %s LIMIT 10""",
            [lang_name, q],
        )
    ]


def validate_word(word: str, lang_name: str) -> bool:
    return bool(
        select(
            """SELECT word FROM core.node
            JOIN core.lang USING (lang_code)
            WHERE lang_name = %s AND word = %s""",
            [lang_name, word],
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
