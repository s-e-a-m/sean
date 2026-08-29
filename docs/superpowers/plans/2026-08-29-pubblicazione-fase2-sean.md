# Pubblicazione web — Fase 2 (sean)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** pubblicare su `/sean/` una reference per segno, generata dal registro del vocabolario, con i glifi di WB e GS affiancati e la provenienza di ciascuno dichiarata.

**Architecture:** il registro (`lib/vocabulary-core.tex` e le dichiarazioni inline di `fonts/gs/font-gs.tex`) è già dati: un `awk` lo legge. La risoluzione del fallback fra font si calcola dai `\seanglyph` e dalla relazione `parent`. I glifi si rendono compilando un unico `.tex` generato, una pagina per coppia (identità, font), e convertendo il PDF con `pdftocairo -svg`.

**Tech Stack:** XeLaTeX (TeX Live 2026), TikZ, circuitikz, font Datalegreya, `pdftocairo` (poppler), `gawk`, `python3`, `bash`.

**Spec:** `docs/superpowers/specs/2026-08-28-pubblicazione-docs-seam-design.md`

**Stato:** eseguito il 2026-08-29. Online e verificato su <https://s-e-a-m.github.io/sean/>.

Deviazioni dal piano, tutte motivate:
`publish.py` in Python e non `publish.sh` in bash — intrecciare TSV, SVG multi-riga e HTML in bash è fragile.
La tabella è HTML e non Markdown: una cella Markdown non può contenere i ritorni a capo di un SVG inline.
Il conteggio delle identità nel piano diceva 43: sono 37 nel canone più 15 estensioni GS.
I check dei test usano `awk -F'\t'` e non `grep -P`: dentro uno script si usa `/usr/bin/grep` (BSD), che non ha `-P`, anche dove la shell interattiva instrada altrove.
Aggiunta una colonna compatta «GS from» al posto di «gs ← wb» ripetuto in ogni riga, e un wrapper `div` per lo scroll della tabella.

## Global Constraints

- Percorso del sito: `/Users/giuseppe/Documents/github/seam/blog/s-e-a-m.github.io` — **SITO**.
- Radice di sean: `/Users/giuseppe/Documents/gitlab/gs/sean` — **SEAN**. Branch di default `main`.
- URL pubblico: `/sean/`. GitHub Pages del repo `s-e-a-m/sean` resta **spento**.
- La collection Jekyll si chiama `sean`, la cartella è `_sean/`.
- La cornice della pagina è in **inglese**; le descrizioni dei segni restano come stanno nel registro (italiano), in attesa della sessione dedicata alla terminologia.
- `pdftocairo` scrive il nero come `rgb(0%, 0%, 0%)`: la sostituzione con `currentColor` deve agganciare quello, non `#000000`.
- Gli id degli SVG (`clip-0`, `glyph-0-0`) vanno prefissati per coppia prima dell'inlining, o collidono nella stessa pagina HTML.
- `dvisvgm` **non** va usato: su questa catena restituisce pagine vuote (PDF specials di xdvipdfmx).
- Il publish non committa. Timbra `generated_from`, `generated_rev`, `generated_at`.
- `make test`, `make render`, `make ref`, `make regress` non devono cambiare comportamento.
- Documentazione una frase per riga.

## File Structure

- `docs/scripts/vocab.awk` — *creato*: dal registro TeX a un TSV `sezione⇥id⇥ancore⇥descrizione`. Una responsabilità: leggere le dichiarazioni.
- `docs/scripts/resolve.py` — *creato*: quali glifi definisce ogni font, la catena `parent`, e per ogni coppia (identità, font) il font che la disegna davvero. Una responsabilità: il fallback.
- `docs/scripts/glyphs.sh` — *creato*: genera il `.tex`, compila, converte, pulisce gli SVG. Una responsabilità: il rendering.
- `docs/scripts/svgclean.py` — *creato*: id unici e `currentColor` su un singolo SVG.
- `docs/scripts/publish.sh` — *creato*: assembla la pagina, il front matter, il blocco di navigazione. Una responsabilità: il trasporto.
- `docs/scripts/test-publish.sh` — *creato*: verifica la catena contro un sito finto.
- `Makefile` — *modificato*: target `svg`, `publish`, `testpub`.
- `README.md`, `CLAUDE.md`, `TODO.md`, `logs/` — *modificati*.
- Nel SITO: `_config.yml`, `_data/navigation.yml`, `_pages/docs.md`, `_sean/index.md` (generato).

---

### Task 1: Estrarre il registro del vocabolario

**Files:**
- Create: `SEAN/docs/scripts/vocab.awk`

**Interfaces:**
- Consumes: `lib/vocabulary-core.tex`, `fonts/gs/font-gs.tex`.
- Produces: su stdout un TSV di quattro campi — `sezione`, `id`, `ancore`, `descrizione` — una riga per identità, nell'ordine di dichiarazione.

- [x] **Step 1: Scrivere il test che fallisce**

Creare `SEAN/docs/scripts/test-vocab.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
out="$(gawk -f "$HERE/vocab.awk" "$ROOT/lib/vocabulary-core.tex")"

fail=0
ok()  { echo "  ok   $1"; }
bad() { echo "  FAIL $1"; fail=1; }

n="$(echo "$out" | wc -l | tr -d ' ')"
if [ "$n" -eq 43 ]; then ok "43 identita estratte"; else bad "43 identita estratte (trovate $n)"; fi
if echo "$out" | grep -qP '^generatori\tgensin\tout\tonde sinusoidali$'; then ok "riga gensin completa"; else bad "riga gensin completa"; fi
if echo "$out" | grep -qP '^modulatori\tam\tin,out,mod\t'; then ok "ancore multiple"; else bad "ancore multiple"; fi
if echo "$out" | grep -qP '^sorgenti\tac\t\t'; then ok "ancore vuote ammesse"; else bad "ancore vuote ammesse"; fi
if [ "$(echo "$out" | cut -f1 | sort -u | wc -l | tr -d ' ')" -eq 7 ]; then ok "7 sezioni"; else bad "7 sezioni"; fi

[ $fail -eq 0 ] && echo "TEST VOCAB OK" || { echo "TEST VOCAB FAIL"; exit 1; }
```

Il nome di sezione è la prima parola significativa del commento `% --- <nome> ---`, minuscola, senza accenti: `sorgenti`, `misura`, `generatori`, `filtri`, `modulatori`, `registrazione`, `trasduttori`.

- [x] **Step 2: Eseguirlo e vederlo fallire**

`chmod +x docs/scripts/test-vocab.sh && docs/scripts/test-vocab.sh`
Atteso: fallisce, `vocab.awk` non esiste.

- [x] **Step 3: Scrivere `vocab.awk`**

```awk
# vocab.awk — dal registro TeX a un TSV: sezione, id, ancore, descrizione.
# Le sezioni sono i commenti "% --- nome ---"; le identita le righe
# \seandeclaresymbol{id}{ancore}  % descrizione
/^% *--- *.* *--- *$/ {
  s = $0
  sub(/^% *--- */, "", s); sub(/ *--- *$/, "", s)
  split(s, a, /[ \/]/); section = tolower(a[1])
  gsub(/[^a-z]/, "", section)
  next
}
/\\seandeclaresymbol\{/ {
  line = $0
  match(line, /\\seandeclaresymbol\{[^}]*\}\{[^}]*\}/)
  decl = substr(line, RSTART, RLENGTH)
  split(decl, p, /[{}]/)
  id = p[2]; anchors = p[4]
  desc = ""
  if (match(line, /%.*$/)) { desc = substr(line, RSTART + 1, RLENGTH - 1); sub(/^ +/, "", desc); sub(/ +$/, "", desc) }
  printf "%s\t%s\t%s\t%s\n", section, id, anchors, desc
}
```

- [x] **Step 4: Eseguirlo e vederlo passare**

Atteso: `TEST VOCAB OK`.
Se il conteggio delle sezioni non torna, aggiustare la normalizzazione del nome, non il test.

- [x] **Step 5: Commit**

```bash
git add docs/scripts/vocab.awk docs/scripts/test-vocab.sh
git commit -m "docs(scripts): il registro del vocabolario e gia dati, un awk lo legge"
```

---

### Task 2: Risolvere la provenienza dei glifi

**Files:**
- Create: `SEAN/docs/scripts/resolve.py`

**Interfaces:**
- Consumes: i file `fonts/*/font-*.tex`.
- Produces: su stdout un TSV `id⇥font⇥font_che_disegna`, una riga per coppia risolvibile. Le coppie che non risolvono non compaiono.

- [x] **Step 1: Scrivere il test che fallisce**

Creare `SEAN/docs/scripts/test-resolve.sh` con questi controlli:

```bash
#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
out="$(python3 "$HERE/resolve.py" "$ROOT")"

fail=0
ok()  { echo "  ok   $1"; }
bad() { echo "  FAIL $1"; fail=1; }

if echo "$out" | grep -qP '^gmic\twb\twb$';   then ok "wb disegna gmic";        else bad "wb disegna gmic"; fi
if echo "$out" | grep -qP '^gmic\tgs\tgs$';   then ok "gs ridefinisce gmic";    else bad "gs ridefinisce gmic"; fi
if echo "$out" | grep -qP '^am\tgs\twb$';     then ok "gs eredita am da wb";    else bad "gs eredita am da wb"; fi
if ! echo "$out" | grep -qP '^preamp\twb\t';  then ok "wb non ha preamp";       else bad "wb non ha preamp"; fi
if echo "$out" | grep -qP '^preamp\tgs\tgs$'; then ok "gs ha preamp";           else bad "gs ha preamp"; fi

[ $fail -eq 0 ] && echo "TEST RESOLVE OK" || { echo "TEST RESOLVE FAIL"; exit 1; }
```

- [x] **Step 2: Eseguirlo e vederlo fallire**

- [x] **Step 3: Scrivere `resolve.py`**

```python
#!/usr/bin/env python3
"""resolve.py — per ogni (identita, font), quale font disegna davvero il glifo.

Uso: resolve.py <radice-di-sean>

Legge i \\seanglyph{font}{id} e la relazione \\seanfont{figlio}{parent=padre},
e risale la catena come fa \\seanresolve nel substrate. Le coppie che non
risolvono non vengono stampate: un glifo assente non e un errore, ma non ha
senso metterlo in tabella.
"""
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
glyphs = {}   # font -> set(id)
parent = {}   # font -> font
order = []    # identita, nell'ordine in cui compaiono

for f in sorted(root.glob("fonts/*/font-*.tex")):
    text = f.read_text()
    for m in re.finditer(r"\\seanfont\{([a-z]+)\}\{([^}]*)\}", text):
        p = re.search(r"parent\s*=\s*([a-z]+)", m.group(2))
        if p:
            parent[m.group(1)] = p.group(1)
    for m in re.finditer(r"\\seanglyph\{([a-z]+)\}\{([a-z0-9]+)\}", text):
        font, ident = m.group(1), m.group(2)
        glyphs.setdefault(font, set()).add(ident)
        if ident not in order:
            order.append(ident)

def resolve(font, ident):
    seen = set()
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
```

- [x] **Step 4: Eseguirlo e vederlo passare**

- [x] **Step 5: Commit**

```bash
git add docs/scripts/resolve.py docs/scripts/test-resolve.sh
git commit -m "docs(scripts): la catena del fallback, calcolata fuori da TeX"
```

---

### Task 3: Rendere i glifi in SVG

**Files:**
- Create: `SEAN/docs/scripts/glyphs.sh`
- Create: `SEAN/docs/scripts/svgclean.py`
- Modify: `SEAN/Makefile` (target `svg`)

**Interfaces:**
- Consumes: l'output di `resolve.py`.
- Produces: `build/svg/<id>-<font>.svg`, uno per coppia, con id prefissati `<id>-<font>-` e i neri sostituiti da `currentColor`; e `build/svg/manifest.tsv` con `id⇥font⇥pagina`.

- [x] **Step 1: Scrivere il test che fallisce**

Creare `SEAN/docs/scripts/test-glyphs.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
"$HERE/glyphs.sh" >/dev/null 2>&1

fail=0
ok()  { echo "  ok   $1"; }
bad() { echo "  FAIL $1"; fail=1; }
D="$ROOT/build/svg"

if [ -f "$D/gmic-wb.svg" ]; then ok "gmic-wb reso"; else bad "gmic-wb reso"; fi
if [ -f "$D/gmic-gs.svg" ]; then ok "gmic-gs reso"; else bad "gmic-gs reso"; fi
if [ -f "$D/am-gs.svg" ];   then ok "am-gs reso (ereditato)"; else bad "am-gs reso (ereditato)"; fi
if [ ! -f "$D/preamp-wb.svg" ]; then ok "preamp-wb non reso"; else bad "preamp-wb non reso"; fi

if grep -q 'currentColor' "$D/gmic-wb.svg"; then ok "colore ereditato dal testo"; else bad "colore ereditato dal testo"; fi
if ! grep -q 'rgb(0%, 0%, 0%)' "$D/gmic-wb.svg"; then ok "nessun nero fisso"; else bad "nessun nero fisso"; fi
if ! grep -q '<?xml' "$D/gmic-wb.svg"; then ok "niente prologo XML"; else bad "niente prologo XML"; fi
if grep -q 'id="gmic-wb-' "$D/gmic-wb.svg"; then ok "id prefissati"; else bad "id prefissati"; fi

# nessun id condiviso fra due file diversi: e la collisione che romperebbe la pagina
a="$(grep -oE 'id="[^"]*"' "$D/gmic-wb.svg" | sort -u)"
b="$(grep -oE 'id="[^"]*"' "$D/gmic-gs.svg" | sort -u)"
if [ -z "$(comm -12 <(echo "$a") <(echo "$b"))" ]; then ok "nessun id in comune"; else bad "nessun id in comune"; fi

[ $fail -eq 0 ] && echo "TEST GLYPHS OK" || { echo "TEST GLYPHS FAIL"; exit 1; }
```

- [x] **Step 2: Eseguirlo e vederlo fallire**

- [x] **Step 3: Scrivere `svgclean.py`**

```python
#!/usr/bin/env python3
"""svgclean.py — prepara un SVG di pdftocairo per essere inlinato in HTML.

Uso: svgclean.py <file.svg> <prefisso>

Fa due cose, entrambe necessarie:
  - prefissa gli id (clip-0, glyph-0-0...) e i riferimenti url(#...), perche
    pdftocairo li numera da zero in ogni file e inlinandone molti nella stessa
    pagina ogni url(#clip-0) risolverebbe al primo;
  - sostituisce il nero, che pdftocairo scrive come rgb(0%, 0%, 0%), con
    currentColor, cosi il glifo prende il colore del testo e resta leggibile
    su tema chiaro e scuro.
Toglie anche il prologo XML, che in HTML non va.
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
s = s.replace('rgb(0%, 0%, 0%)', 'currentColor')

path.write_text(s.strip() + "\n")
```

- [x] **Step 4: Scrivere `glyphs.sh`**

Genera un `.tex` con una pagina per coppia, nell'ordine del manifest; compila una volta; converte pagina per pagina.

```bash
#!/usr/bin/env bash
# glyphs.sh — rende in SVG ogni coppia (identita, font) che risolve.
#
# Le pagine sono generate qui, non da un \foreach in TeX: solo cosi il numero
# di pagina resta legato con certezza alla coppia. dvisvgm non e utilizzabile
# (XeLaTeX emette PDF specials), quindi si passa da pdftocairo.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT="$ROOT/build/svg"
WORK="$ROOT/build/glyphwork"

[ -d "$ROOT/fonts/wb/src" ] || { echo "glyphs: il submodule fonts/wb non e inizializzato" >&2; exit 1; }

rm -rf "$OUT" "$WORK"; mkdir -p "$OUT" "$WORK"

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
[ -f "$WORK/glyphs.pdf" ] || { echo "glyphs: la compilazione e fallita, vedi $WORK/glyphs.log" >&2; exit 1; }

page=0
: > "$OUT/manifest.tsv"
while IFS=$'\t' read -r id font src; do
  page=$((page + 1))
  pdftocairo -svg -f "$page" -l "$page" "$WORK/glyphs.pdf" "$OUT/$id-$font.svg"
  python3 "$HERE/svgclean.py" "$OUT/$id-$font.svg" "$id-$font"
  printf '%s\t%s\t%s\t%s\n' "$id" "$font" "$src" "$page" >> "$OUT/manifest.tsv"
done < "$WORK/pairs.tsv"

echo "  resi $page glifi in build/svg/"
```

- [x] **Step 5: Eseguire il test e vederlo passare**

Se la compilazione fallisce, leggere `build/glyphwork/glyphs.log`: la causa piu probabile e un glifo che richiede `circuitikz` o il font Datalegreya assente.

- [x] **Step 6: Aggiungere il target al Makefile**

In `SEAN/Makefile`, aggiungere `svg` a `.PHONY` e:

```make
svg: ; @docs/scripts/glyphs.sh
```

Verificare che `make test`, `make render` e `make regress` continuino a funzionare: `build/` e nuovo e non tocca `test/ref/`.

- [x] **Step 7: Commit**

```bash
git add docs/scripts/glyphs.sh docs/scripts/svgclean.py docs/scripts/test-glyphs.sh Makefile
git commit -m "docs(scripts): i glifi in SVG, con gli id resi unici per l'inlining"
```

---

### Task 4: Assemblare e pubblicare la pagina

**Files:**
- Create: `SEAN/docs/scripts/publish.sh`
- Create: `SEAN/docs/scripts/navblock.py` (copia deliberata di quello di faust-libraries)
- Create: `SEAN/docs/scripts/test-publish.sh`
- Modify: `SEAN/Makefile` (target `publish`, `testpub`)

**Interfaces:**
- Consumes: `vocab.awk`, `build/svg/manifest.tsv`, gli SVG puliti.
- Produces: `<sito>/_sean/index.md` e il blocco `sean` in `<sito>/_data/navigation.yml`.

- [x] **Step 1: Scrivere il test che fallisce**

`test-publish.sh` costruisce un sito finto in una dir temporanea, lancia `publish.sh`, e verifica: la pagina esiste; ha `permalink: /sean/`; contiene la provenienza; contiene almeno un `<svg` inline; contiene `currentColor`; nomina `gmic` e `preamp`; dichiara `wb` come sorgente di `am` per il font GS; il blocco `# BEGIN sean` c'e ed e unico dopo due esecuzioni. Contare i check con `EXPECTED_CHECKS`, come in faust-libraries.

- [x] **Step 2: Eseguirlo e vederlo fallire**

- [x] **Step 3: Scrivere `publish.sh`**

Struttura della pagina generata:

```markdown
---
title: "SEAN — Notation Reference"
permalink: /sean/
toc: true
generated_from: sean
generated_rev: <sha>
generated_at: <data>
---

<!-- GENERATO — non modificare qui: la fonte e lib/vocabulary-core.tex e i font in fonts/ -->
# SEAN — Sustained ElectroAcoustic Notation

<cornice in inglese: cos'e, frase vs font, come si legge la tabella, cosa
significa la colonna della provenienza>

## <sezione>

| Sign | Anchors | WB | GS | GS source | Description |
|---|---|---|---|---|---|
| `gmic` | out | <svg…> | <svg…> | gs | microfono generico |
| `am` | in,out,mod | <svg…> | <svg…> | wb | d'ampiezza |
```

Le identita GS-only hanno la cella WB vuota (`—`).
Le sezioni seguono l'ordine del registro.

- [x] **Step 4: Eseguirlo e vederlo passare**

- [x] **Step 5: Aggiungere i target al Makefile**

```make
SITE ?= $(HOME)/Documents/github/seam/blog/s-e-a-m.github.io

publish: svg ; @docs/scripts/publish.sh $(SITE)
testpub: ; @docs/scripts/test-publish.sh
```

- [x] **Step 6: Commit**

---

### Task 5: Il sito accoglie la collection

**Files:**
- Modify: `SITO/_config.yml`, `SITO/_pages/docs.md`
- Generati: `SITO/_sean/index.md`, blocco `sean` in `SITO/_data/navigation.yml`

- [x] **Step 1: Dichiarare la collection**

In `_config.yml`, sotto `collections:`, aggiungere `sean: { output: true, permalink: /sean/:path/ }`; e in `defaults:` un blocco per `type: sean` con `layout: single`, `author_profile: false`, `toc: true`, `sidebar: nav: "sean"`.

- [x] **Step 2: Pubblicare e leggere il diff**

```bash
cd SEAN && make publish
cd SITO && git status --short && git diff --stat
```

- [x] **Step 3: Costruire e verificare in locale**

```bash
cd SITO && bundle exec jekyll build
ls _site/sean/index.html
grep -c '<svg' _site/sean/index.html
```

Atteso: la pagina esiste e contiene un `<svg>` per ogni coppia resa.

- [x] **Step 4: Aggiornare la pagina hub**

In `_pages/docs.md`, sostituire il `Coming soon.` della sezione SEAN con il link a `/sean/`.

- [x] **Step 5: Ispezione visiva**

`bundle exec jekyll serve`, aprire `/sean/`, e verificare che i glifi si vedano — **in entrambe le skin**, chiara e scura. E il controllo che conta: che ogni glifo sia il suo, non quello del vicino, che e come si manifesta una collisione di id.

- [x] **Step 6: Commit e push**

---

### Task 6: Documentazione

**Files:**
- Modify: `SEAN/README.md`, `SEAN/CLAUDE.md`, `SEAN/TODO.md`
- Create: `SEAN/logs/2026-08-29-pubblicazione-web.md`
- Modify: `SITO/README.md` (riga della collection `sean`)

- [x] **Step 1: README** — sezione *Documentazione online* con l'URL e `make publish`.
- [x] **Step 2: CLAUDE.md** — come si pubblica, e che GitHub Pages del repo resta spento.
- [x] **Step 3: TODO.md** — la lingua delle descrizioni del vocabolario (sessione dedicata) e il submodule `fonts/wb` da spostare su `s-e-a-m`, la cui priorita sale ora che la pagina e pubblica.
- [x] **Step 4: Log datato** e commit.

---

## Rischi noti

- **Il submodule `fonts/wb`** e indispensabile: senza, `glyphs.sh` si ferma con un messaggio esplicito. Chi clona pubblicamente il repo non lo ottiene, quindi non puo rigenerare la pagina.
- **`build/` va in `.gitignore`** se non c'e gia: gli SVG sono artefatti.
- **La compilazione e una sola** per tutti i glifi, ma `pdftocairo` viene invocato una volta per pagina: con una sessantina di coppie sono pochi secondi, non un problema.
