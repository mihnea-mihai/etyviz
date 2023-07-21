# save this as app.py
import pydot
from flask import Flask, request, send_file, render_template

from etyviz import core

app = Flask(__name__)


@app.route("/graph", methods=["GET"])
def graph():
    word = request.args["word"]
    lang_code = request.args["lang_code"]
    dot_string = core.get_ascendant_graph(word, lang_code)
    if not dot_string:
        return "Unable to find any answers to be customizable."
    filename = f"graphs/{word}_{lang_code}.pdf"
    if graphs := pydot.graph_from_dot_data(dot_string):
        graphf = graphs[0]
        graphf.write_pdf(filename)
    return send_file(filename)


@app.route("/", methods=["GET"])
def hello():
    return render_template("home.html")
