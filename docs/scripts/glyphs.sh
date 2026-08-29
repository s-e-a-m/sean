#!/usr/bin/env bash
# glyphs.sh — rende in SVG ogni coppia (identità, font) che risolve.
#
# Le pagine sono generate qui, non da un \foreach in TeX: solo così il numero
# di pagina resta legato con certezza alla coppia.
# dvisvgm non è utilizzabile — XeLaTeX emette la grafica come PDF specials via
# xdvipdfmx, e dvisvgm legge i PostScript specials di dvips: restituirebbe
# pagine vuote. Si passa quindi da pdftocairo.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT="$ROOT/build/svg"
WORK="$ROOT/build/glyphwork"

[ -f "$ROOT/fonts/wb/font-wb.tex" ] || {
  echo "glyphs: il submodule fonts/wb non è inizializzato — 'git submodule update --init'" >&2
  exit 1
}

rm -rf "$OUT" "$WORK"
mkdir -p "$OUT" "$WORK"

python3 "$HERE/resolve.py" "$ROOT" > "$WORK/pairs.tsv"

{
  echo '\documentclass[tikz]{standalone}'
  echo '\input{lib/style.tex}'
  echo '\usepackage{circuitikz}'
  echo '\usetikzlibrary{sean}'
  echo '\input{fonts/wb/font-wb.tex}'
  echo '\input{fonts/gs/font-gs.tex}'
  echo '\begin{document}'
  while IFS=$'\t' read -r id font src; do
    echo "\\tikz{\\pic[sean font=$font] {sean symbol=$id};}"
  done < "$WORK/pairs.tsv"
  echo '\end{document}'
} > "$WORK/glyphs.tex"

( cd "$WORK" && TEXINPUTS="$ROOT:" xelatex -interaction=nonstopmode -halt-on-error glyphs.tex >/dev/null 2>&1 )
[ -f "$WORK/glyphs.pdf" ] || { echo "glyphs: compilazione fallita, vedi $WORK/glyphs.log" >&2; exit 1; }

page=0
: > "$OUT/manifest.tsv"
while IFS=$'\t' read -r id font src; do
  page=$((page + 1))
  pdftocairo -svg -f "$page" -l "$page" "$WORK/glyphs.pdf" "$OUT/$id-$font.svg" 2>/dev/null
  python3 "$HERE/svgclean.py" "$OUT/$id-$font.svg" "$id-$font"
  printf '%s\t%s\t%s\t%s\n' "$id" "$font" "$src" "$page" >> "$OUT/manifest.tsv"
done < "$WORK/pairs.tsv"

echo "  resi $page glifi in build/svg/"
