#!/usr/bin/env python3
"""resolve.py — per ogni (identità, font), quale font disegna davvero il glifo.

Uso: resolve.py <radice-di-sean>

Legge i \\seanglyph{font}{id} e la relazione \\seanfont{figlio}{parent=padre},
e risale la catena come fa \\seanresolve nel substrate.
Le coppie che non risolvono non vengono stampate: un glifo assente non è un
errore — il substrate disegna un segnaposto tratteggiato — ma in tabella
sarebbe rumore.
"""
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
glyphs: dict[str, set[str]] = {}
parent: dict[str, str] = {}
order: list[str] = []

for f in sorted(root.glob("fonts/*/font-*.tex")):
    text = f.read_text()
    for m in re.finditer(r"\\seanfont\{([a-z0-9]+)\}\{([^}]*)\}", text):
        p = re.search(r"parent\s*=\s*([a-z0-9]+)", m.group(2))
        if p:
            parent[m.group(1)] = p.group(1)
    for m in re.finditer(r"\\seanglyph\{([a-z0-9]+)\}\{([a-z0-9]+)\}", text):
        font, ident = m.group(1), m.group(2)
        glyphs.setdefault(font, set()).add(ident)
        if ident not in order:
            order.append(ident)


def resolve(font: str, ident: str) -> str | None:
    seen: set[str] = set()
    cur = font
    while cur and cur not in seen:
        seen.add(cur)
        if ident in glyphs.get(cur, ()):
            return cur
        cur = parent.get(cur, "")
    return None


for ident in order:
    for font in sorted(glyphs):
        src = resolve(font, ident)
        if src:
            print(f"{ident}\t{font}\t{src}")
