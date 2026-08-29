#!/usr/bin/env python3
"""svgclean.py — prepara un SVG di pdftocairo per essere inlinato in HTML.

Uso: svgclean.py <file.svg> <prefisso>

Due cose, entrambe necessarie:

  - prefissa gli id (clip-0, glyph-0-0…) e i riferimenti url(#…): pdftocairo
    li numera da zero in ogni file, e inlinandone molti nella stessa pagina
    ogni url(#clip-0) risolverebbe al primo, ritagliando un glifo con la
    maschera di un altro;
  - sostituisce il nero, che pdftocairo scrive come rgb(0%, 0%, 0%) e non
    come #000000, con currentColor: così il glifo prende il colore del testo
    e resta leggibile su tema chiaro e su tema scuro.

Toglie anche il prologo XML, che dentro l'HTML non va.
"""
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
prefix = sys.argv[2]
s = path.read_text()

s = re.sub(r"<\?xml[^>]*\?>\s*", "", s)
s = re.sub(r'id="([^"]+)"', lambda m: f'id="{prefix}-{m.group(1)}"', s)
s = re.sub(r"url\(#([^)]+)\)", lambda m: f"url(#{prefix}-{m.group(1)})", s)
s = s.replace("rgb(0%, 0%, 0%)", "currentColor")

path.write_text(s.strip() + "\n")
