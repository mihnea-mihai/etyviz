# Etyviz

![](/static/assets/img/Etyviz.drawio.svg)

**Etyviz** is an etymology explorer
rendering etymological relationships in a static graph format.
Its main purpose is to present etymological information in a
standardized, print-friendly format to be used by
language enthusiasts and scholars alike.


## Output

## How it works

**Etyviz** takes the output of 
[Wiktextract](https://github.com/tatuylonen/wiktextract)
(more precisely the parsed dumps at 
[kaikki.org](https://kaikki.org/dictionary/rawdata.html)),
then extracts the relevant sections to build a 
[PostgreSQL](https://www.postgresql.org/) database of linked entities.

It queries the generated database based on the input given
in an intuitive [UI interface](http://etyviz.mihai.lu/) and uses
[Graphviz](https://graphviz.org/) to render the output relationships graph.

## Installation and deployment

See [instructions](/docs/server.md) for server configuration.

## Features



## Personal note

This project is the successor of
[Wiketym](https://github.com/mihnea-mihai/wiketym),
my first attempt at automatically generating etymology visualizations.

This is in turn inspired from when
I was painstakingly exploring etymologies
and manually drawing the link maps
at [Etimologia vieții](https://etimologiavietii.wordpress.com/).
At that time I would have never imagined I will be the one
to create such a tool, yet here we are. :blue_heart:
