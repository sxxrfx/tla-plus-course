#!/bin/zsh
# usage: tlc.sh Name  -> checks specs/Name.tla with specs/Name.cfg using real TLC, in a private metadir
R="$(cd "$(dirname "$0")" && pwd)"; cd "$R/specs"; java -XX:+UseParallelGC -cp "${TLA2TOOLS:-$R/tla2tools.jar}" tlc2.TLC -workers auto -metadir "$(mktemp -d)" -config "$1.cfg" "$1.tla" 2>&1 | grep -vE '^(TLC2 Version|Running|Parsing|Semantic|Starting|Computing|Finished computing|Implied|Checking|Progress|The depth|The average|Finished in)' 
