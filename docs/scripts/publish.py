#!/usr/bin/env python3
"""publish.py — assembla la reference di sean e la copia nel sito.

Uso: publish.py <percorso-del-sito>

Mette insieme tre cose che esistono già: il registro del vocabolario (letto da
vocab.awk), la catena del fallback (resolve.py, via il manifest di glyphs.sh) e
i glifi in SVG. Non committa: il diff nel repo del sito si legge a mano.

La tabella è HTML e non Markdown perché un SVG inline è multi-riga, e una cella
di tabella Markdown non può contenere ritorni a capo.
"""
import datetime
import pathlib
import subprocess
import sys

if len(sys.argv) < 2:
    sys.exit("uso: publish.py <percorso-del-sito>")

site = pathlib.Path(sys.argv[1])
root = pathlib.Path(__file__).resolve().parents[2]
scripts = root / "docs" / "scripts"
svgdir = root / "build" / "svg"

if not site.is_dir():
    sys.exit(f"publish: sito non trovato: {site}")
if not (svgdir / "manifest.tsv").exists():
    sys.exit("publish: mancano i glifi — lancia prima 'make svg'")

rev = subprocess.run(["git", "-C", str(root), "rev-parse", "--short", "HEAD"],
                     capture_output=True, text=True).stdout.strip()
today = datetime.date.today().isoformat()


def vocab(path):
    out = subprocess.run(["gawk", "-f", str(scripts / "vocab.awk"), str(path)],
                         capture_output=True, text=True, check=True).stdout
    rows = []
    for line in out.splitlines():
        section, ident, anchors, desc = (line.split("\t") + ["", "", "", ""])[:4]
        rows.append((section, ident, anchors, desc))
    return rows


entries = vocab(root / "lib" / "vocabulary-core.tex") + vocab(root / "fonts" / "gs" / "font-gs.tex")

# manifest: (identità, font) -> font che disegna davvero
source = {}
fonts = set()
for line in (svgdir / "manifest.tsv").read_text().splitlines():
    ident, font, src, _page = line.split("\t")
    source[(ident, font)] = src
    fonts.add(font)
fonts = sorted(fonts)


def glyph(ident, font):
    f = svgdir / f"{ident}-{font}.svg"
    return f.read_text().strip() if f.exists() else ""


def slug(text):
    return "".join(c if c.isalnum() else "-" for c in text.lower()).strip("-")


sections = []
for section, ident, anchors, desc in entries:
    if not sections or sections[-1][0] != section:
        sections.append((section, []))
    sections[-1][1].append((ident, anchors, desc))

out = []
out.append("---")
out.append('title: "SEAN — Notation Reference"')
out.append("permalink: /sean/")
out.append("toc: true")
out.append("generated_from: sean")
out.append(f"generated_rev: {rev}")
out.append(f"generated_at: {today}")
out.append("---")
out.append("")
out.append("<!-- GENERATO — non modificare qui: la fonte è lib/vocabulary-core.tex e i font in fonts/ -->")
out.append("# SEAN — Sustained ElectroAcoustic Notation")
out.append("")
out.append("A TikZ library for writing electroacoustic block diagrams as scores.")
out.append("The signs come from Walter Branchi's *Tecnologie della musica elettronica* (1976), transcribed and extended for contemporary use.")
out.append("")
out.append("The system separates a **phrase** from a **font**.")
out.append("A phrase is the abstract diagram: identities (`gmic`, `am`, `lspk`…) connected by name, independent of any style.")
out.append("A font is the hand of an author or a tradition that draws those identities.")
out.append("Change the font and the chain stays; the sign changes.")
out.append("")
out.append("A font may declare a parent and redraw only what it wants, inheriting the rest.")
out.append("`gs` declares `wb` as its parent, so it draws its own microphone and falls back to Branchi's for the modulators.")
out.append("The tables below show, for each identity, what each font actually draws — inheritance included — and the **source** column says which font the glyph really comes from.")
out.append("An empty cell means that font has no glyph for that identity, not even through a parent.")
out.append("")
out.append("The descriptions are the ones in the register itself, in Italian, as transcribed from Branchi's Appendix 6.")
out.append("")
out.append(f"Generated from [github.com/s-e-a-m/sean](https://github.com/s-e-a-m/sean) at `{rev}`.")
out.append("")

for section, rows in sections:
    out.append(f"## {section}")
    out.append("")
    out.append('<table class="sean-glyphs">')
    head = ["Sign", "Anchors"] + [f.upper() for f in fonts] + ["Source", "Description"]
    out.append("<thead><tr>" + "".join(f"<th>{h}</th>" for h in head) + "</tr></thead>")
    out.append("<tbody>")
    for ident, anchors, desc in rows:
        cells = [f"<td><code>{ident}</code></td>",
                 f"<td><code>{anchors}</code></td>" if anchors else "<td></td>"]
        for font in fonts:
            g = glyph(ident, font)
            cells.append(f'<td class="glyph">{g}</td>' if g else "<td></td>")
        srcs = []
        for font in fonts:
            s = source.get((ident, font))
            if s and s != font:
                srcs.append(f"{font} ← {s}")
        cells.append("<td>" + (", ".join(srcs) if srcs else "—") + "</td>")
        cells.append(f"<td>{desc}</td>")
        out.append("<tr>" + "".join(cells) + "</tr>")
    out.append("</tbody>")
    out.append("</table>")
    out.append("")

coll = site / "_sean"
coll.mkdir(parents=True, exist_ok=True)
(coll / "index.md").write_text("\n".join(out))

# sidebar: una voce per sezione, come àncora nella pagina
nav = ["sean:", '  - title: "Notation Reference"', "    url: /sean/", "    children:"]
for section, _rows in sections:
    nav.append(f'      - title: "{section}"')
    nav.append(f"        url: /sean/#{slug(section)}")
subprocess.run(["python3", str(scripts / "navblock.py"),
                str(site / "_data" / "navigation.yml"), "sean"],
               input="\n".join(nav), text=True, check=True)

drawn = sum(1 for k in source)
print(f"  publish sean: {len(entries)} identità, {drawn} glifi, {len(sections)} sezioni")
