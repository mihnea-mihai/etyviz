import unicodedata

GREEK_EXCEPTIONS = [
    unicodedata.lookup("COMBINING ACUTE ACCENT"),
    unicodedata.lookup("COMBINING COMMA ABOVE"),
]


with open("sql/etyviz.rules", "w", encoding="utf-8") as file:
    for code in range(0x110000):  # Unicode range
        c = chr(code)
        if unicodedata.category(c) in {"Sm", "So"}:
            continue
        cname = unicodedata.name(c, "")
        if (
            "HANGUL" in cname
            or "COMPATIBILITY" in cname
            or "HIRAGANA" in cname
            or "KATAKANA" in cname
        ):
            continue
        conv = unicodedata.normalize("NFD", c)

        if unicodedata.combining(c):
            file.write(f"{c}\n")
            continue
        if len(conv) > 1:
            stripped = "".join(
                convc
                for convc in conv
                if not unicodedata.combining(convc)
                or ("GREEK" in cname and convc in GREEK_EXCEPTIONS)
            )
            back = unicodedata.normalize("NFC", stripped)
            file.write(f"{c}\t{back}\n")
            print(c, back)
