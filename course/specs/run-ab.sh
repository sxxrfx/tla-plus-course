#!/bin/zsh
# usage: run.sh Module cfg  -> real TLC in a private metadir, from this directory or a sibling
D="$(cd "$(dirname "$0")" && pwd)"; cd "${3:-$D}"
java -XX:+UseParallelGC -cp "${TLA2TOOLS:-$D/../tla2tools.jar}" tlc2.TLC -workers auto -metadir "$(mktemp -d)" -config "$2.cfg" "$1.tla" 2>&1 | grep -vE '^(TLC2 Version|Running|Parsing|Semantic|Starting|Computing|Finished computing|Implied|Checking|Progress|The average|Finished in)'
