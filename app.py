# save this as app.py
import pydot
import graphviz
from flask import Flask, request, send_file, render_template

from etyviz import core, ui

app = Flask(__name__)


@app.route("/graph", methods=["GET"])
def graph():
    word = request.args["word"]
    lang_name = request.args["lang"]
    graph_type = request.args["graph"]
    filter_lang = request.args.get("filter-lang", "")
    match graph_type:
        case "history":
            dot_string = core.get_ascendant_graph(word, lang_name)
        case "children":
            dot_string = core.get_descendant_graph(word, lang_name, filter_lang)
        case "relationships":
            dot_string = core.get_related_graph(word, lang_name, filter_lang)
        case _:
            return "", 500
    if not dot_string:
        return "", 404
    filename = f"graphs/{word}_{lang_name}_{graph_type}_{filter_lang}.pdf"
    gv = graphviz.Source(dot_string)
    gv.unflatten(1000, True, chain=10).render(outfile=filename)
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
    return render_template("home.html", version="1.0.0")


@app.route("/api/suggest/lang", methods=["GET"])
def suggest_lang():
    """Return a HTML dropdown of filtered language names based on input letters."""
    langs = ui.suggest_lang(request.args["lang"])
    return render_template("dropdown.html", elems=langs)


@app.route("/api/validate/lang", methods=["GET"])
def validate_lang():
    lang = request.args["lang"]
    valid = ui.validate_lang(lang)
    return "", 204 if valid else 404


@app.route("/api/suggest/word", methods=["GET"])
def suggest_word():
    part_word = request.args["word"]
    lang_name = request.args["lang"]
    # if len(part_word) < 3:
    #     return "", 400
    words = ui.suggest_word(lang_name, part_word)
    return render_template("dropdown.html", elems=words)


@app.route("/api/validate/word", methods=["GET"])
def validate_word():
    word = request.args["word"]
    lang = request.args["lang"]
    valid = ui.validate_word(word, lang)
    return "", 204 if valid else 404


if __name__ == "__main__":
    app.run(port=80, host="0.0.0.0")
