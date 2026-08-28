# Pubblicazione web — Fasi 0 e 1 (sito + faust-libraries)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** portare le reference di `faust-libraries` sul sito `s-e-a-m.github.io` a un indirizzo coerente col nome del repo, dentro un percorso di navigazione, con un `make publish` ripetibile che pubblica solo ciò che è davvero documentato.

**Architecture:** il sito Jekyll è l'hub unico; ogni repo sorgente genera il proprio Markdown e lo copia nella propria collection con un `make publish` locale, che non committa. Le GitHub Pages di repo restano spente perché, a parità di path, la project page ha la precedenza sul user site.

**Tech Stack:** Jekyll 3.10 con tema remoto `mmistakes/minimal-mistakes` (skin `dark`), Ruby via Bundler, `gawk`, `bash`, `python3`, `gh` CLI.

**Spec:** `docs/superpowers/specs/2026-08-28-pubblicazione-docs-seam-design.md` (nel repo `sean`)

## Global Constraints

- Percorso del sito: `/Users/giuseppe/Documents/github/seam/blog/s-e-a-m.github.io` — di seguito **SITO**.
- Percorso di faust-libraries: `/Users/giuseppe/Documents/github/seam/librerie/faust-libraries` — di seguito **FL**.
- Entrambi i repo hanno branch di default `master`.
- L'URL pubblico di una documentazione è **il nome del repo**: `/faust-libraries/`, `/sean/`, `/seam-ltm/`. Unica eccezione dichiarata: la pagina hub `/docs/`, che non appartiene a nessun repo.
- GitHub Pages di repo resta **spento** su `faust-libraries`, `sean`, `seam-ltm`.
- Il `publish` non committa e non pusha mai: lascia il working tree del SITO sporco.
- I file generati portano il front matter di provenienza (`generated_from`, `generated_rev`, `generated_at`) e un commento `<!-- GENERATO … -->` come prima riga del corpo.
- La lingua delle pagine del sito è l'inglese.
- Scrivere tutta la documentazione Markdown **una frase per riga** (convenzione del workspace).
- Non usare array bash: lo script deve girare anche su `bash` 3.2 (default di macOS).

## File Structure

**Nel SITO:**
- `_config.yml` — *modificato*: permalink della collection `libraries`.
- `_libraries/basic.md`, `_libraries/math.md` — *modificati* poi *rigenerati*: front matter.
- `_libraries/index.md` — *generato*: indice della suite.
- `_pages/docs.md` — *creato*: pagina hub dei tre progetti.
- `_data/navigation.yml` — *modificato*: voce `Docs` nel menu, blocco `libraries` delimitato da marker.
- `README.md` — *modificato*: mappa delle collection e regole per i file generati.

**In FL:**
- `doc/scripts/publish.sh` — *creato*: genera front matter, applica il gate di copertura, scrive pagine, indice e blocco di navigazione. Unica responsabilità: trasportare nel sito ciò che `make doc` ha prodotto.
- `doc/scripts/navblock.py` — *creato*: sostituisce un blocco delimitato da marker dentro un file YAML. Trenta righe, deliberatamente duplicate negli altri repo invece di creare una dipendenza fra repo.
- `doc/scripts/test-publish.sh` — *creato*: verifica il publish contro un sito finto in una directory temporanea.
- `doc/Makefile` — *modificato*: target `publish` con variabile `SITE`.
- `README.md`, `CLAUDE.md`, `TODO.md`, `logs/` — *modificati*.

---

### Task 1: Liberare `/faust-libraries/` e spostare la collection

Il repo `faust-libraries` ha GitHub Pages attivo e serve il proprio README su `/faust-libraries/`.
Finché resta acceso, il sito può costruire pagine a quel path ma non vederle mai servite.
L'ordine dei passi non è negoziabile.

**Files:**
- Modify: `SITO/_config.yml` (blocco `collections:`)
- Modify: `SITO/_libraries/basic.md:3`, `SITO/_libraries/math.md:3`

**Interfaces:**
- Consumes: nulla.
- Produces: il path `/faust-libraries/` libero e assegnato alla collection `libraries` del sito.

- [ ] **Step 1: Verificare lo stato di partenza**

```bash
curl -s -o /dev/null -w "%{http_code}\n" -L https://s-e-a-m.github.io/faust-libraries/
curl -s -L https://s-e-a-m.github.io/faust-libraries/ | grep -o '<title>[^<]*</title>'
```

Atteso: `200`, e un titolo `<title>faust-libraries | SEAM Libraries</title>` — cioè la project page, non il sito.

- [ ] **Step 2: Spegnere GitHub Pages sul repo faust-libraries**

```bash
gh api -X DELETE repos/s-e-a-m/faust-libraries/pages
gh api repos/s-e-a-m/faust-libraries/pages
```

Atteso: la seconda chiamata risponde `404 Not Found`.

- [ ] **Step 3: Verificare che il path si sia liberato**

```bash
curl -s -o /dev/null -w "%{http_code}\n" -L https://s-e-a-m.github.io/faust-libraries/
```

Atteso: `404`.
La propagazione può richiedere un minuto; se resta `200`, riprovare fra sessanta secondi prima di proseguire.

- [ ] **Step 4: Spostare il permalink della collection**

In `SITO/_config.yml`, sostituire nel blocco `collections:`:

```yaml
collections:
  libraries:
    output: true
    permalink: /faustlibraries/:path/
```

con:

```yaml
collections:
  libraries:
    output: true
    permalink: /faust-libraries/:path/
```

- [ ] **Step 5: Aggiornare il front matter delle due pagine esistenti**

In `SITO/_libraries/basic.md` la riga 3 diventa `permalink: /faust-libraries/basic/`.
In `SITO/_libraries/math.md` la riga 3 diventa `permalink: /faust-libraries/math/`.

- [ ] **Step 6: Costruire il sito in locale e verificare i path**

```bash
cd /Users/giuseppe/Documents/github/seam/blog/s-e-a-m.github.io
bundle exec jekyll build
ls _site/faust-libraries/basic/index.html _site/faust-libraries/math/index.html
[ -d _site/faustlibraries ] && echo "ERRORE: vecchio path ancora generato" || echo "vecchio path assente: ok"
```

Atteso: i due `index.html` esistono, e `_site/faustlibraries` non esiste.

- [ ] **Step 7: Commit nel SITO**

```bash
cd /Users/giuseppe/Documents/github/seam/blog/s-e-a-m.github.io
git add _config.yml _libraries/basic.md _libraries/math.md
git commit -m "site(libraries): serve la reference su /faust-libraries/, come il repo

La project page di s-e-a-m/faust-libraries è stata spenta: a parità di
path la project page vince sul user site, ed è il motivo per cui la
collection era finita su /faustlibraries/ senza trattino."
```

---

### Task 2: Pagina hub `/docs/` e voce di menu

Le pagine delle librerie sono online da settimane ma nessuna voce di menu le nomina: esistono e non si trovano.
Questo task chiude il buco e crea il punto in cui i tre progetti si presentano insieme.

**Files:**
- Create: `SITO/_pages/docs.md`
- Modify: `SITO/_data/navigation.yml` (blocco `main:`)

**Interfaces:**
- Consumes: i permalink `/faust-libraries/` (Task 1).
- Produces: la pagina `/docs/`, a cui i piani di `sean` e `seam-ltm` aggiungeranno il proprio blocco.

- [ ] **Step 1: Creare la pagina hub**

Creare `SITO/_pages/docs.md` con esattamente questo contenuto:

```markdown
---
title: "Documentation"
permalink: /docs/
layout: single
author_profile: false
toc: false
---

SEAM maintains three bodies of work that document themselves: a notation for electroacoustic block diagrams, a set of Faust DSP libraries, and a suite of VST3 plugins.
They are separate repositories, but they describe the same practice — and where they overlap, the pages cross-reference each other.

## Faust Libraries

DSP libraries for sustained electroacoustic music: filters, reverberation, ambisonics, analysis.
Every function is documented at the source, in the `.lib` files themselves, and the reference below is generated from them.

[Browse the library reference](/faust-libraries/)

## SEAN — Sustained ElectroAcoustic Notation

A TikZ library for writing electroacoustic block diagrams as scores, transcribed from Walter Branchi's *Tecnologie della musica elettronica* (1976) and extended to contemporary use.

Coming soon.

## SEAM-LTM — Learning Through Making

Sixteen VST3 plugins built directly on the Steinberg SDK: format converters, signal generators, and measurement tools.

Coming soon.
```

- [ ] **Step 2: Aggiungere la voce al menu principale**

In `SITO/_data/navigation.yml`, nel blocco `main:`, aggiungere come **prima** voce:

```yaml
main:
  - title: "Docs"
    url: /docs/
  - title: "Posts"
    url: /posts/
```

Le altre voci (`Categories`, `Tags`, `About`) restano invariate, nello stesso ordine.

- [ ] **Step 3: Costruire e verificare**

```bash
cd /Users/giuseppe/Documents/github/seam/blog/s-e-a-m.github.io
bundle exec jekyll build
ls _site/docs/index.html
grep -c 'href="/docs/"' _site/faust-libraries/basic/index.html
```

Atteso: `_site/docs/index.html` esiste, e il grep trova almeno una occorrenza — la voce di menu compare anche dentro le pagine della collection.

- [ ] **Step 4: Commit**

```bash
cd /Users/giuseppe/Documents/github/seam/blog/s-e-a-m.github.io
git add _pages/docs.md _data/navigation.yml
git commit -m "site(nav): una voce Docs e la pagina che presenta i tre progetti

Le reference erano raggiungibili solo per URL diretto: nessuna voce di
menu le nominava."
```

---

### Task 3: `publish.sh` con gate di copertura

Misurato il 2026-08-28: solo `seam.basic` (10 funzioni) e `seam.math` (19) hanno funzioni documentate alla fonte; le altre diciotto ne hanno zero, e `dwt`/`stereophony` generano file vuoti.
Lo script pubblica solo ciò che è documentato e dichiara la copertura.

**Files:**
- Create: `FL/doc/scripts/publish.sh`
- Create: `FL/doc/scripts/test-publish.sh`
- Modify: `FL/doc/Makefile` (nuovo target `publish`)

**Interfaces:**
- Consumes: i file `FL/doc/build/seam.*.md` prodotti da `make doc`.
- Produces: `publish.sh <sito>` scrive `<sito>/_libraries/<nome>.md` per ogni libreria documentata e stampa sull'ultima riga utile `  copertura: N/M`.

- [ ] **Step 1: Scrivere il test che fallisce**

Creare `FL/doc/scripts/test-publish.sh`:

```bash
#!/usr/bin/env bash
# test-publish.sh — verifica publish.sh contro un sito finto in una dir temporanea.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/_libraries" "$TMP/_data"
: > "$TMP/_data/navigation.yml"

"$HERE/publish.sh" "$TMP" > "$TMP/out.txt" 2>&1 || { echo "publish.sh è uscito con errore:"; cat "$TMP/out.txt"; exit 1; }

fail=0
ok()   { echo "  ok   $1"; }
bad()  { echo "  FAIL $1"; fail=1; }

if [ -f "$TMP/_libraries/basic.md" ]; then ok "basic pubblicata"; else bad "basic pubblicata"; fi
if [ -f "$TMP/_libraries/math.md" ]; then ok "math pubblicata"; else bad "math pubblicata"; fi
if [ ! -f "$TMP/_libraries/filters.md" ]; then ok "filters esclusa dal gate"; else bad "filters esclusa dal gate"; fi
if [ ! -f "$TMP/_libraries/dwt.md" ]; then ok "dwt esclusa dal gate"; else bad "dwt esclusa dal gate"; fi

if grep -q '^permalink: /faust-libraries/basic/$' "$TMP/_libraries/basic.md"; then ok "permalink corretto"; else bad "permalink corretto"; fi
if grep -q '^generated_from: faust-libraries$' "$TMP/_libraries/basic.md"; then ok "provenienza presente"; else bad "provenienza presente"; fi

sed -n '/^<!-- GENERATO/,$p' "$TMP/_libraries/basic.md" | tail -n +2 > "$TMP/corpo.md"
if diff -q "$TMP/corpo.md" "$HERE/../build/seam.basic.md" >/dev/null; then ok "corpo identico al generato"; else bad "corpo identico al generato"; fi

if grep -q 'copertura: 2/20' "$TMP/out.txt"; then ok "rapporto di copertura"; else bad "rapporto di copertura"; fi

if [ $fail -eq 0 ]; then echo "TEST PUBLISH OK"; else echo "TEST PUBLISH FAIL"; exit 1; fi
```

Renderlo eseguibile: `chmod +x FL/doc/scripts/test-publish.sh`.

- [ ] **Step 2: Eseguire il test e vederlo fallire**

```bash
cd /Users/giuseppe/Documents/github/seam/librerie/faust-libraries
make -C doc md
doc/scripts/test-publish.sh
```

Atteso: fallisce subito con `publish.sh è uscito con errore` — lo script non esiste ancora.

- [ ] **Step 3: Scrivere `publish.sh`**

Creare `FL/doc/scripts/publish.sh`:

```bash
#!/usr/bin/env bash
# publish.sh — trasporta le reference generate nel sito SEAM.
#
# Uso: publish.sh <percorso-del-sito>
#
# Pubblica SOLO le librerie che hanno almeno una funzione documentata alla
# fonte (banner Grame, che faustlib2md.awk rende come "### `(prefix.)nome`").
# Le altre restano fuori: una pagina di soli titoli è peggio di nessuna pagina.
# Non committa e non pusha: il controllo editoriale resta un gesto umano.

set -uo pipefail

SITE="${1:-}"
[ -n "$SITE" ] || { echo "uso: publish.sh <percorso-del-sito>" >&2; exit 1; }

HERE="$(cd "$(dirname "$0")" && pwd)"
BUILD="$HERE/../build"
COLL="$SITE/_libraries"

[ -d "$SITE" ]  || { echo "publish: sito non trovato: $SITE" >&2; exit 1; }
[ -d "$BUILD" ] || { echo "publish: manca $BUILD — lancia prima 'make -C doc doc'" >&2; exit 1; }

REV="$(git -C "$HERE" rev-parse --short HEAD)"
TODAY="$(date +%F)"

mkdir -p "$COLL"

published=""
skipped=""
total=0

for f in "$BUILD"/seam.*.md; do
  total=$((total + 1))
  base="$(basename "$f" .md)"     # seam.basic
  name="${base#seam.}"            # basic
  nfun="$(grep -c '^### `(' "$f")"
  if [ "$nfun" -eq 0 ]; then
    skipped="$skipped $name"
    continue
  fi
  {
    printf -- '---\n'
    printf 'title: "Faust Libraries · %s"\n' "$name"
    printf 'permalink: /faust-libraries/%s/\n' "$name"
    printf 'toc: true\n'
    printf 'generated_from: faust-libraries\n'
    printf 'generated_rev: %s\n' "$REV"
    printf 'generated_at: %s\n' "$TODAY"
    printf -- '---\n\n'
    printf '<!-- GENERATO — non modificare qui: la fonte è faust-libraries/src/%s.lib -->\n' "$base"
    cat "$f"
  } > "$COLL/$name.md"
  published="$published $name"
  echo "  publish $name ($nfun funzioni)"
done

npub="$(echo "$published" | wc -w | tr -d ' ')"
echo "  copertura: $npub/$total"
[ -n "$skipped" ] && echo "  non documentate alla fonte:$skipped"
exit 0
```

Renderlo eseguibile: `chmod +x FL/doc/scripts/publish.sh`.

- [ ] **Step 4: Eseguire il test e vederlo passare**

```bash
cd /Users/giuseppe/Documents/github/seam/librerie/faust-libraries
doc/scripts/test-publish.sh
```

Atteso: tutte le righe `ok`, ultima riga `TEST PUBLISH OK`.

- [ ] **Step 5: Aggiungere il target `publish` al Makefile**

In `FL/doc/Makefile`, aggiungere `publish` e `test` alla riga `.PHONY:` e in fondo al file:

```make
# Il Makefile vive in doc/, e `make -C doc` esegue con CWD=doc/:
# il percorso relativo si conta da lì, non dalla radice del repo.
SITE ?= ../../../blog/s-e-a-m.github.io

publish: doc
	@scripts/publish.sh $(SITE)

test:
	@scripts/test-publish.sh
```

Verificare: `make -C doc test` stampa `TEST PUBLISH OK`.

- [ ] **Step 6: Commit**

```bash
cd /Users/giuseppe/Documents/github/seam/librerie/faust-libraries
git add doc/scripts/publish.sh doc/scripts/test-publish.sh doc/Makefile
git commit -m "doc: publish nel sito SEAM, con gate di copertura

Pubblica solo le librerie che hanno funzioni documentate alla fonte e
dichiara la copertura: oggi 2 su 20. Una pagina di soli titoli è peggio
di nessuna pagina."
```

---

### Task 4: Indice della suite

La pagina `/faust-libraries/` deve esistere: è ciò che la vecchia project page faceva male, servendo il README grezzo con un tema estraneo.
Si genera dai file già prodotti, estraendo nome e prefisso dall'intestazione.

**Files:**
- Modify: `FL/doc/scripts/publish.sh` (aggiunta della generazione dell'indice)
- Modify: `FL/doc/scripts/test-publish.sh` (nuovi controlli)

**Interfaces:**
- Consumes: la variabile `published` di `publish.sh` (Task 3).
- Produces: `<sito>/_libraries/index.md` con `permalink: /faust-libraries/`.

- [ ] **Step 1: Aggiungere i controlli al test**

In `FL/doc/scripts/test-publish.sh`, prima del blocco finale `if [ $fail -eq 0 ]`, aggiungere:

```bash
if [ -f "$TMP/_libraries/index.md" ]; then ok "indice generato"; else bad "indice generato"; fi
if grep -q '^permalink: /faust-libraries/$' "$TMP/_libraries/index.md"; then ok "permalink dell'indice"; else bad "permalink dell'indice"; fi
if grep -q '\[basic\](/faust-libraries/basic/)' "$TMP/_libraries/index.md"; then ok "indice linka basic"; else bad "indice linka basic"; fi
if grep -q '`sba`' "$TMP/_libraries/index.md"; then ok "indice riporta il prefisso"; else bad "indice riporta il prefisso"; fi
if ! grep -q 'filters' "$TMP/_libraries/index.md"; then ok "indice non linka le escluse"; else bad "indice non linka le escluse"; fi
```

- [ ] **Step 2: Eseguire il test e vederlo fallire**

```bash
cd /Users/giuseppe/Documents/github/seam/librerie/faust-libraries
doc/scripts/test-publish.sh
```

Atteso: `FAIL indice generato` e le altre quattro, poi `TEST PUBLISH FAIL`.

- [ ] **Step 3: Generare l'indice in `publish.sh`**

In `FL/doc/scripts/publish.sh`, prima della riga `npub="$(echo "$published" | wc -w | tr -d ' ')"`, inserire:

```bash
# --- indice della suite ---------------------------------------------------
{
  printf -- '---\n'
  printf 'title: "Faust Libraries"\n'
  printf 'permalink: /faust-libraries/\n'
  printf 'toc: false\n'
  printf 'generated_from: faust-libraries\n'
  printf 'generated_rev: %s\n' "$REV"
  printf 'generated_at: %s\n' "$TODAY"
  printf -- '---\n\n'
  printf '<!-- GENERATO — non modificare qui: la fonte sono i .lib di faust-libraries/src/ -->\n'
  printf '# SEAM Faust Libraries\n\n'
  printf 'DSP libraries for sustained electroacoustic music.\n'
  printf 'Every entry below is generated from the comments in its own `.lib` source.\n\n'
  printf '| Library | Prefix | |\n'
  printf '|---|---|---|\n'
  for name in $published; do
    src="$BUILD/seam.$name.md"
    prefix="$(sed -n 's/.*official prefix is `\([a-z]*\)`.*/\1/p' "$src" | head -1)"
    desc="$(sed -n '3p' "$src" | sed 's/ Its official prefix is.*//')"
    printf '| [%s](/faust-libraries/%s/) | `%s` | %s |\n' "$name" "$name" "$prefix" "$desc"
  done
  printf '\nThe source is at [github.com/s-e-a-m/faust-libraries](https://github.com/s-e-a-m/faust-libraries).\n'
} > "$COLL/index.md"
```

- [ ] **Step 4: Eseguire il test e vederlo passare**

```bash
cd /Users/giuseppe/Documents/github/seam/librerie/faust-libraries
doc/scripts/test-publish.sh
```

Atteso: tutte `ok`, poi `TEST PUBLISH OK`.

- [ ] **Step 5: Commit**

```bash
cd /Users/giuseppe/Documents/github/seam/librerie/faust-libraries
git add doc/scripts/publish.sh doc/scripts/test-publish.sh
git commit -m "doc(publish): l'indice della suite, generato dai .lib

Sostituisce la vecchia project page, che serviva il README grezzo con un
tema estraneo al sito."
```

---

### Task 5: Blocco di navigazione delimitato da marker

`_data/navigation.yml` è l'unico file del sito scritto da tutti e tre i repo.
Ognuno possiede un blocco fra due marker e non guarda gli altri.

**Attenzione:** il file contiene già una chiave `libraries:` scritta a mano.
Va rimossa in questo task, altrimenti dopo il primo publish la chiave comparirebbe due volte nello stesso YAML.

**Files:**
- Create: `FL/doc/scripts/navblock.py`
- Modify: `FL/doc/scripts/publish.sh`
- Modify: `FL/doc/scripts/test-publish.sh`
- Modify: `SITO/_data/navigation.yml` (rimozione del blocco manuale)

**Interfaces:**
- Consumes: la variabile `published` di `publish.sh`.
- Produces: `navblock.py <file.yml> <nome> < stdin` sostituisce il blocco `# BEGIN <nome>` … `# END <nome>`, creandolo in coda se assente.

- [ ] **Step 1: Aggiungere i controlli al test**

In `FL/doc/scripts/test-publish.sh`, prima del blocco finale, aggiungere:

```bash
if grep -q '# BEGIN libraries' "$TMP/_data/navigation.yml"; then ok "blocco nav aperto"; else bad "blocco nav aperto"; fi
if grep -q '# END libraries' "$TMP/_data/navigation.yml"; then ok "blocco nav chiuso"; else bad "blocco nav chiuso"; fi
if grep -q 'url: /faust-libraries/basic/' "$TMP/_data/navigation.yml"; then ok "nav elenca basic"; else bad "nav elenca basic"; fi

"$HERE/publish.sh" "$TMP" > /dev/null 2>&1
n="$(grep -c '# BEGIN libraries' "$TMP/_data/navigation.yml")"
if [ "$n" -eq 1 ]; then ok "publish idempotente sul nav"; else bad "publish idempotente sul nav (blocchi: $n)"; fi
```

- [ ] **Step 2: Eseguire il test e vederlo fallire**

Atteso: `FAIL blocco nav aperto` e seguenti, poi `TEST PUBLISH FAIL`.

- [ ] **Step 3: Scrivere `navblock.py`**

Creare `FL/doc/scripts/navblock.py`:

```python
#!/usr/bin/env python3
"""navblock.py — sostituisce un blocco delimitato da marker dentro un file YAML.

Uso: navblock.py <file.yml> <nome-blocco>   (il contenuto arriva da stdin)

Il blocco è delimitato da "# BEGIN <nome>" e "# END <nome>".
Se non esiste, viene aggiunto in coda. Se esiste, viene sostituito: così il
publish è idempotente e i tre repo che scrivono nello stesso file non si
pestano i piedi.
"""
import pathlib
import sys

nav = pathlib.Path(sys.argv[1])
name = sys.argv[2]
body = sys.stdin.read().rstrip("\n")

begin = f"# BEGIN {name} (generato — non modificare a mano)"
end = f"# END {name}"
block = f"{begin}\n{body}\n{end}\n"

text = nav.read_text() if nav.exists() else ""

if begin in text and end in text:
    head = text.split(begin)[0]
    tail = text.split(end, 1)[1].lstrip("\n")
    text = head + block + ("\n" + tail if tail else "")
else:
    text = (text.rstrip("\n") + "\n\n" if text.strip() else "") + block

nav.write_text(text)
```

Renderlo eseguibile: `chmod +x FL/doc/scripts/navblock.py`.

- [ ] **Step 4: Chiamarlo da `publish.sh`**

In `FL/doc/scripts/publish.sh`, subito dopo la generazione dell'indice, inserire:

```bash
# --- blocco di navigazione ------------------------------------------------
{
  printf 'libraries:\n'
  printf '  - title: "Library Reference"\n'
  printf '    url: /faust-libraries/\n'
  printf '    children:\n'
  for name in $published; do
    src="$BUILD/seam.$name.md"
    prefix="$(sed -n 's/.*official prefix is `\([a-z]*\)`.*/\1/p' "$src" | head -1)"
    printf '      - title: "%s (%s)"\n' "$name" "$prefix"
    printf '        url: /faust-libraries/%s/\n' "$name"
  done
} | python3 "$HERE/navblock.py" "$SITE/_data/navigation.yml" libraries
```

- [ ] **Step 5: Eseguire il test e vederlo passare**

```bash
cd /Users/giuseppe/Documents/github/seam/librerie/faust-libraries
doc/scripts/test-publish.sh
```

Atteso: tutte `ok`, poi `TEST PUBLISH OK`.
Il controllo `publish idempotente sul nav` è quello che conta: lancia il publish due volte e verifica che il blocco resti uno solo.

- [ ] **Step 6: Rimuovere il blocco `libraries:` manuale dal sito**

In `SITO/_data/navigation.yml`, cancellare queste righe (il commento e la chiave scritti a mano):

```yaml
# Sidebar nav for the _libraries collection (see _config.yml defaults)
libraries:
  - title: "Library Reference"
    children:
      - title: "basic (sba)"
        url: /faustlibraries/basic/
      - title: "math (sma)"
        url: /faustlibraries/math/
```

Il blocco `main:` resta com'è.

- [ ] **Step 7: Commit in FL**

```bash
cd /Users/giuseppe/Documents/github/seam/librerie/faust-libraries
git add doc/scripts/navblock.py doc/scripts/publish.sh doc/scripts/test-publish.sh
git commit -m "doc(publish): la sidebar si scrive da sé, in un blocco marcato

navigation.yml è l'unico file del sito che tutti e tre i repo toccano:
ognuno possiede un blocco fra due marker e non guarda gli altri."
```

---

### Task 6: Pubblicazione reale e verifica sul sito

**Files:**
- Modify (generati): `SITO/_libraries/basic.md`, `SITO/_libraries/math.md`, `SITO/_libraries/index.md`, `SITO/_data/navigation.yml`

**Interfaces:**
- Consumes: `make -C doc publish` (Task 3-5), il permalink e il menu (Task 1-2).
- Produces: il sito pronto da pushare.

- [ ] **Step 1: Rigenerare la documentazione e pubblicare**

```bash
cd /Users/giuseppe/Documents/github/seam/librerie/faust-libraries
make -C doc publish
```

Atteso: due righe `publish basic (10 funzioni)` e `publish math (19 funzioni)`, poi `copertura: 2/20` e l'elenco delle diciotto escluse.

- [ ] **Step 2: Leggere il diff del sito prima di accettarlo**

```bash
cd /Users/giuseppe/Documents/github/seam/blog/s-e-a-m.github.io
git status --short
git diff --stat
```

Atteso: modificati `_libraries/basic.md`, `_libraries/math.md`, `_data/navigation.yml`; nuovo `_libraries/index.md`.
Nel diff delle due pagine esistenti devono comparire **solo** i tre campi di provenienza e il commento `<!-- GENERATO … -->`: se cambia il corpo, fermarsi e capire perché.

- [ ] **Step 3: Costruire e verificare in locale**

```bash
cd /Users/giuseppe/Documents/github/seam/blog/s-e-a-m.github.io
bundle exec jekyll build
ls _site/faust-libraries/index.html _site/faust-libraries/basic/index.html _site/faust-libraries/math/index.html
grep -c 'faust-diagram' _site/faust-libraries/basic/index.html
```

Atteso: i tre `index.html` esistono; il grep trova almeno cinque diagrammi — prova che gli SVG inline hanno attraversato il publish intatti.

- [ ] **Step 4: Ispezione visiva**

```bash
cd /Users/giuseppe/Documents/github/seam/blog/s-e-a-m.github.io
bundle exec jekyll serve
```

Aprire `http://127.0.0.1:4000/docs/`, poi seguire il link alle librerie.
Verificare: la voce `Docs` è nel menu; `/faust-libraries/` mostra la tabella con `basic` e `math` e i rispettivi prefissi; la sidebar elenca due voci; i diagrammi Faust si vedono sulla skin scura.
Fermare il server con `Ctrl-C`.

- [ ] **Step 5: Commit e push del sito**

```bash
cd /Users/giuseppe/Documents/github/seam/blog/s-e-a-m.github.io
git add _libraries _data/navigation.yml
git commit -m "libraries: reference e indice pubblicati da faust-libraries

Generati da 'make -C doc publish'. Copertura 2/20: le altre diciotto
librerie non hanno ancora funzioni documentate alla fonte."
git push origin master
```

- [ ] **Step 6: Verificare online**

Attendere il build di GitHub Pages (uno o due minuti), poi:

```bash
for u in / /docs/ /faust-libraries/ /faust-libraries/basic/ /faust-libraries/math/; do
  printf "%-32s " "$u"
  curl -s -o /dev/null -w "%{http_code}\n" -L "https://s-e-a-m.github.io$u"
done
curl -s -o /dev/null -w "vecchio path: %{http_code}\n" -L https://s-e-a-m.github.io/faustlibraries/basic/
```

Atteso: cinque `200`, e `vecchio path: 404`.

---

### Task 7: Documentazione dei repo toccati

**Files:**
- Modify: `FL/README.md`, `FL/CLAUDE.md`, `FL/TODO.md`
- Create: `FL/logs/2026-08-28-pubblicazione-web.md`
- Modify: `SITO/README.md`

- [ ] **Step 1: `FL/README.md` — sezione sulla documentazione online**

Aggiungere in fondo:

```markdown
## Documentazione online

La reference è pubblicata su <https://s-e-a-m.github.io/faust-libraries/>.

Si rigenera dai sorgenti e si trasporta nel sito con:

    make -C doc publish

Vengono pubblicate solo le librerie che hanno funzioni documentate alla fonte, nel formato dei banner Grame; il comando stampa la copertura e l'elenco delle mancanti.
Il publish non committa: il diff nel repo del sito va letto e accettato a mano.
```

- [ ] **Step 2: `FL/CLAUDE.md` — la regola non ovvia**

Aggiungere una sezione:

```markdown
## Pubblicazione web

La documentazione vive sul sito `s-e-a-m.github.io`, nella collection `_libraries`, all'URL `/faust-libraries/` — lo stesso nome del repo.

**GitHub Pages di questo repo deve restare spento.**
A parità di path la project page ha la precedenza sul user site: riattivandola, le pagine del sito verrebbero costruite e mai servite, senza alcun errore visibile.
```

- [ ] **Step 3: `FL/TODO.md` — le diciotto librerie da documentare**

Aggiungere una sezione con una voce per libreria non ancora documentata alla fonte:

```markdown
## Documentazione alla fonte (per la pubblicazione web)

Solo `basic` e `math` hanno funzioni documentate nel formato dei banner Grame.
Le altre generano pagine di soli titoli e restano escluse dal publish.

- [ ] `seam.filters.lib` — 205 righe di testo, zero banner di funzione #faust-libraries #avanza
- [ ] `seam.analyzers.lib` — 192 righe, zero banner #faust-libraries #avanza
- [ ] `seam.gerzon.lib` — 171 righe, zero banner #faust-libraries #avanza
- [ ] `seam.pdclone.lib` — 145 righe, zero banner #faust-libraries #avanza
- [ ] `seam.discipio.lib` — 85 righe, zero banner #faust-libraries #avanza
- [ ] `seam.schroeder.lib` — 85 righe, zero banner #faust-libraries #avanza
- [ ] `seam.cyclone.lib` — 63 righe, zero banner #faust-libraries #avanza
- [ ] `seam.ambisonics.lib` — 51 righe, zero banner #faust-libraries #avanza
- [ ] `seam.freeverb.lib` — 48 righe, zero banner #faust-libraries #avanza
- [ ] `seam.linkwitz.lib` — 35 righe, zero banner #faust-libraries #avanza
- [ ] `seam.moorer.lib` — 32 righe, zero banner #faust-libraries #avanza
- [ ] `seam.reverbs.lib` — 18 righe, zero banner #faust-libraries #avanza
- [ ] `seam.roads.lib` — 18 righe, zero banner #faust-libraries #avanza
- [ ] `seam.noises.lib` — 10 righe, zero banner #faust-libraries #avanza
- [ ] `seam.csound.lib` — 3 righe, zero banner #faust-libraries #avanza
- [ ] `seam.ffunctions.lib` — 3 righe, zero banner #faust-libraries #avanza
- [ ] `seam.dwt.lib` — nessun commento estraibile #faust-libraries #avanza
- [ ] `seam.stereophony.lib` — nessun commento estraibile #faust-libraries #avanza
```

- [ ] **Step 4: `SITO/README.md` — le regole del sito**

Aggiungere:

```markdown
## Collections di documentazione

| Collection | Cartella | URL | Sorgente |
|---|---|---|---|
| `libraries` | `_libraries/` | `/faust-libraries/` | repo `faust-libraries`, `make -C doc publish` |

I file di queste cartelle sono **generati**: non vanno modificati qui.
La fonte è il repo indicato nel front matter (`generated_from`, `generated_rev`), e il publish successivo sovrascrive ogni modifica fatta a mano.

`_data/navigation.yml` contiene blocchi delimitati da marker `# BEGIN <nome>` / `# END <nome>`, scritti dai repo sorgente.
Fuori dai marker si scrive a mano; dentro, no.

GitHub Pages dei repo `faust-libraries`, `sean` e `seam-ltm` deve restare **spento**: a parità di path la project page vince sul user site.
```

- [ ] **Step 5: Log di sessione in FL**

Se `FL/logs/` non esiste, crearla.
Creare `FL/logs/2026-08-28-pubblicazione-web.md` con questo contenuto:

```markdown
# Log di sessione — 2026-08-28 — Pubblicazione della reference sul sito SEAM

## Obiettivo
Portare la reference generata da `doc/` sul sito `s-e-a-m.github.io`, a un indirizzo coerente col nome del repo, con un comando ripetibile.

## Stato trovato
Il repo aveva GitHub Pages attivo e serviva il proprio README con il tema di default su `/faust-libraries/`.
Il sito serviva la reference curata su `/faustlibraries/`, senza trattino: era l'unico path libero, perché a parità di path la project page ha la precedenza sul user site.

Rigenerando `doc/build/` da zero è emerso che solo `seam.basic` (10 funzioni) e `seam.math` (19) hanno funzioni documentate alla fonte.
Le altre diciotto non hanno i banner di funzione nel formato Grame e producono pagine di soli titoli; `dwt` e `stereophony` producono file vuoti.

## Decisioni
L'URL è il nome del repo: `/faust-libraries/`.
GitHub Pages di repo spento, così il path resta al sito.
`publish.sh` con gate di copertura: pubblica solo le librerie documentate e dichiara il rapporto.

## Azioni
- Spento GitHub Pages sul repo.
- Aggiunti `doc/scripts/publish.sh`, `doc/scripts/navblock.py`, `doc/scripts/test-publish.sh` e i target `publish`/`test` in `doc/Makefile`.
- Pubblicate due reference più l'indice della suite; sidebar generata in un blocco marcato di `_data/navigation.yml`.
- Aggiornati README, CLAUDE e TODO.

## Punti aperti
- Diciotto librerie da documentare alla fonte: una voce per libreria in `TODO.md`.

## Chi
**Chi:** Claude (agente), su indicazione di Giuseppe.
```

- [ ] **Step 6: Commit**

```bash
cd /Users/giuseppe/Documents/github/seam/librerie/faust-libraries
git add README.md CLAUDE.md TODO.md logs/
git commit -m "docs: la pubblicazione web, e le diciotto librerie da documentare"
cd /Users/giuseppe/Documents/github/seam/blog/s-e-a-m.github.io
git add README.md
git commit -m "docs: mappa delle collection e regole per i file generati"
```

---

## Cosa resta fuori da questo piano

- **Fase 2 — `sean`**: target `svg` con `dvisvgm`, estrattore `awk` sul vocabolario, `currentColor`, reference per segno. Piano separato.
- **Fase 3 — `seam-ltm`**: registro `doc/plugins.yml` e i due generatori. Piano separato.
- **Documentare i diciotto `.lib`**: lavoro di scrittura tecnica, tracciato nel `TODO.md` di `faust-libraries` (Task 7), non di pubblicazione.
- **Portare il repo del sito allo standard del workspace** (`CLAUDE.md`, `TODO.md`, `logs/`): decisione a parte.
