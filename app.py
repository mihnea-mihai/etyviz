# save this as app.py
import pydot
from flask import Flask, request, send_file, render_template

from etyviz import core

app = Flask(__name__)


@app.route("/graph", methods=["GET"])
def graph():
    word = request.args["word"]
    lang_name = request.args["lang"]
    dot_string = core.get_ascendant_graph(word, lang_name)
    if not dot_string:
        return "", 404
    filename = f"graphs/{word}_{lang_name}.pdf"
    if graphs := pydot.graph_from_dot_data(dot_string):
        graphf = graphs[0]
        graphf.write_pdf(filename)
    return send_file(filename)


@app.route("/view_all", methods=["GET"])
def view_all():
    dot_string = core.view_all()
    if not dot_string:
        return "", 404
    filename = f"graphs/view_all.svg"
    if graphs := pydot.graph_from_dot_data(dot_string):
        graphf = graphs[0]
        graphf.write_svg(filename)
    return send_file(filename)


@app.route("/", methods=["GET"])
def hello():
    return render_template("home.html")


@app.route("/api/suggest/lang", methods=["GET"])
def suggest_lang():
    part_lang = request.args["part_lang"]
    if len(part_lang) < 3:
        return "", 400
    return core.suggest_lang(part_lang), 200


@app.route("/api/suggest/word", methods=["GET"])
def suggest_word():
    part_word = request.args["part_word"]
    if len(part_word) < 3:
        return "", 400
    return core.suggest_word(part_word), 200


@app.route("/api/validate/word", methods=["GET"])
def validate_word():
    word = request.args["word"]
    valid = core.validate_word(word)
    return "", 204 if valid else 404


@app.route("/api/validate/lang", methods=["GET"])
def validate_lang():
    lang = request.args["lang"]
    valid = core.validate_lang(lang)
    return "", 204 if valid else 404


if __name__ == "__main__":
    app.run(port=80, host="0.0.0.0")
