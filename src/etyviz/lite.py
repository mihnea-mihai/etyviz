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
]
# Reconstruction:Proto-Indo-European/wódr̥


def insert_lines(lite: bool = False, batch_size: int = 10000):
    start = datetime.datetime.now()
    print("Import started at: ", start)
    i = 0
    with open("storage/raw-wiktextract-data.json", encoding="utf-8") as file:
        with open(
            "storage/raw-wiktextract-data-lite.json", mode="w", encoding="utf-8"
        ) as out:
            for line in file:
                i += 1
                jdoc = json.loads(line)
                word = jdoc.get("word")
                if word in lemmas:
                    out.write(json.dumps(jdoc) + "\n")
                    print(word)
                if i % 100000 == 0:
                    print("Total processed rows:", i)

    end = datetime.datetime.now()
    print("Import ended at: ", end)

    print("Total time: ", end - start)


if __name__ == "__main__":
    insert_lines()
