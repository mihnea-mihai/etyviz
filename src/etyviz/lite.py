import datetime
import json

lemmas = [
    "χάρτης",
    "credere",
    "credo",
    "pesticide",
    "pest",
    "-i-",
    "-cide",
    "ten",
    "ice",
    "is",
    "-vocus",
    "wekʷ",
    "compute",
    "water",
    "wæter",
    "watar",
    "watōr",
    "wódr̥",
    "-wed",
    "ǵʰer-",
    "mus",
    "mouse",
    "mous",
    "mūs",
    "*muh₂s",
    "lup",
    "lupus",
    "lukʷos",
    "wĺ̥kʷos",
    "fire",
    "fyr",
    "-wr̥",
    "péh₂wr̥",
    "etymology",
    "etymologia",
    "ἐτυμολογία",
    "ἐτυμόλογος",
    "ἔτυμος",
    "-ία",
    "ἔτυμον",
    "λόγος",
    "Michael",
    "מיכאל",
    "מי",
    "כ־",
    "אל",
]

titles = ["Reconstruction:Proto-Indo-European/wédōr"]


def insert_lines():
    start = datetime.datetime.now()
    print("Import started at: ", start)
    i = 0
    with open("storage/raw-wiktextract-data.jsonl", encoding="utf-8") as file:
        with open(
            "storage/test/raw-wiktextract-data.jsonl", mode="w", encoding="utf-8"
        ) as out:
            for line in file:
                i += 1
                jdoc = json.loads(line)
                word = jdoc.get("word")
                title = jdoc.get("title")
                if word in lemmas or title in titles:
                    out.write(json.dumps(jdoc, ensure_ascii=False) + "\n")
                    print(word)
                if i % 100000 == 0:
                    print("Total processed rows:", i)

    end = datetime.datetime.now()
    print("Import ended at: ", end)

    print("Total time: ", end - start)


if __name__ == "__main__":
    insert_lines()
