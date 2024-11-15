#!/usr/bin/env bash

cd $(dirname "$0")

set +e
latexmk --shell-escape -pdf -f -interaction=nonstopmode -jobname=INITIAL_RESEARCH_DOC main.tex > log.log 2>&1
set -e
latexmk -c -pdf INITIAL_RESEARCH_DOC.pdf

