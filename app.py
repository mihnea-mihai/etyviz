# save this as app.py
import pydot
from flask import Flask, request, send_file, render_template
from etyviz import db
from etyviz.langs import Language
from etyviz.words import Word
from etyviz.links import Link
import time

app = Flask(__name__)
app.jinja_options["trim_blocks"] = True
app.jinja_options["lstrip_blocks"] = True


@app.route("/langs")
def langs():
    return render_template("langs.html.jinja")


@app.route("/words")
def words():
    return render_template("words.html.jinja")


@app.route("/api/langs")
def api_langs():
    qlang = request.args.get("qlang", "")
    data = db.execute("SELECT * FROM ui.get_languages(%s)", [qlang])
    return render_template("api/langs.html.jinja", data=data)


@app.route("/lang/<lang_code>")
def lang(lang_code):
    return render_template("lang.html.jinja", lang=Language.get(lang_code))


@app.route("/word/<node_id>")
def word(node_id: int):
    return render_template("word.html.jinja", word=Word.get(node_id))


@app.route("/api/words")
def api_words():
    qlang_code = request.args.get("qlang_code", "")
    qword = request.args.get("qword", "")
    data = Word.query(qlang_code, qword)
    return render_template("api/words.html.jinja", data=data)


@app.route("/api/links")
def api_links():
    source_id = request.args.get("source_id")
    target_id = request.args.get("target_id")
    data = Link.query(source_id, target_id)
    if source_id and not target_id:
        type_ = "source"
    else:
        type_ = "target"
    return render_template("api/links.html.jinja", data=data, type=type_)


@app.route("/")
def home():
    return render_template("home.html.jinja", version="1.1.0")


@app.errorhandler(404)
def not_found(e):
    if "/api/" in request.path:
        return "⚠️ API error"
    return render_template("404.html.jinja")


if __name__ == "__main__":
    # app.run(port=80, host="0.0.0.0")
    app.run()
