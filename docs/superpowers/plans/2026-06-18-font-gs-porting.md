# Font GS — porting dei simboli del diagramma timpano — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aggiungere a `sean` un font `gs` (la "mano" di Giuseppe Silvi) che ridisegna gli 8 segni del channel strip del timpano, dopo aver riordinato l'albero del repo per una crescita ordinata.

**Architecture:** `gs` è un font con `parent=wb`: ridisegna i propri glifi e ricade su WB per il resto. Vive in una "stanza propria" (`fonts/gs/` con `font-gs.tex` + `test/` + `ref/`). Il motore (`lib/`, `test/`) resta condiviso in root. I riferimenti di regressione sono per-stanza.

**Tech Stack:** XeLaTeX, TikZ, circuitikz (per il filtro `hpf`), `pgfkeys`. Build/test via `make` (xelatex + grep `SEAN-OK` + `pdftoppm` per la regressione visiva).

## Global Constraints

- Compilazione: **XeLaTeX** (`xelatex -interaction=nonstopmode -halt-on-error`).
- Contratto glifo: `\seanglyph{gs}{<id>}{<disegno-tikz>}`; ogni glifo posa le ancore dichiarate via `\seananchor{<nome>}{<coord>}`.
- Identità nuove dichiarate inline nel file-font con `\seandeclaresymbol{<id>}{<ancore>}` (come `lib/bridge-circuitikz.tex`). **Non** modificare `lib/vocabulary-core.tex` (canone WB).
- Glifi GS **centrati sull'origine**, senza coordinate assolute, senza label (le label sono `\node` a livello di diagramma). Preservare gli spessori di tratto delle macro storiche (default, non `very thin`).
- `\input` root-relative nei test di stanza (`\input{test/seantest.tex}`, `\input{fonts/gs/font-gs.tex}`), risolti via `TEXINPUTS=<root>:`.
- Ref per-stanza: motore e documenti → `test/ref/`; font → `fonts/<font>/ref/`.
- Regola di progetto: circuitikz → WB → GS. Niente deduplica WB ora (bonifica futura dell'utente).
- Commit solo quando i target di test passano. Branch: lavorare su `main` solo se l'utente lo consente; altrimenti creare un branch prima del primo commit.

---

## Task 1: Riordino dell'albero (doc→docs, log→logs)

**Files:**
- Move: `doc/catalog.tex` → `docs/catalog.tex`
- Move: `log/` → `logs/`
- Modify: `Makefile:6` (RENDER_SRCS: `doc/catalog.tex` → `docs/catalog.tex`)
- Modify: `README.md` (blocco architettura: `doc/` → `docs/`, aggiungere `logs/`)

**Interfaces:**
- Consumes: niente.
- Produces: `docs/catalog.tex` (il documento-catalogo, path interni `../lib` `../fonts` invariati perché `docs/` è alla stessa profondità di `doc/`); `logs/` come cartella dei log di sessione.

- [ ] **Step 1: Spostare i file tracciati**

```bash
cd /Users/giuseppe/Documents/gitlab/gs/sean
git mv doc/catalog.tex docs/catalog.tex
git mv log logs
rm -rf doc   # rimuove eventuali artefatti non tracciati (catalog.aux/.log/.pdf/.png)
```

- [ ] **Step 2: Aggiornare il riferimento nel Makefile**

In `Makefile` riga 6, sostituire `doc/catalog.tex` con `docs/catalog.tex`:

```make
RENDER_SRCS = test/place.tex test/override.tex test/domains.tex test/font-wb.tex test/rotate.tex test/bridge.tex docs/catalog.tex
```

- [ ] **Step 3: Aggiornare il blocco architettura nel README**

In `README.md`, nel blocco ```` ``` ```` dell'architettura, cambiare la riga `doc/` in `docs/` e la sua descrizione, e (se presente) riferimenti a `log/` in `logs/`. Esempio di righe risultanti:

```
docs/
  catalog.tex                documento-catalogo
  superpowers/               spec e piani (brainstorming/writing-plans)
logs/                        log di sessione (uno per data)
```

- [ ] **Step 4: Verificare che il catalogo renda dalla nuova posizione**

Run: `make clean && make render`
Expected: nell'output compare `  rendered catalog` (e gli altri render senza `SKIP`).

- [ ] **Step 5: Verificare che i test del motore restino verdi**

Run: `make test`
Expected: termina con `ALL TEX OK` (nessun `FAIL`).

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: riordino albero (doc->docs, log->logs)"
```

---

## Task 2: Generalizzare il Makefile alle stanze per-font

**Files:**
- Modify: `Makefile` (target `test`, `render`, `ref`, `regress`)

**Interfaces:**
- Consumes: la struttura di Task 1.
- Produces: scoperta automatica dei test in `test/*.tex` **e** `fonts/*/test/*.tex`; risoluzione del `ref/` per-stanza (font → `fonts/<font>/ref/`, resto → `test/ref/`). Ogni test è compilato dalla propria directory con `TEXINPUTS=<root>:`.

- [ ] **Step 1: Riscrivere il target `test` con scoperta a due sorgenti**

Sostituire il target `test:` con:

```make
TESTS = $(filter-out test/seantest.tex,$(wildcard test/*.tex) $(wildcard fonts/*/test/*.tex))

test: ; @ok=1; for f in $(TESTS); do d=$$(dirname $$f); b=$$(basename $$f); \
	echo "== $$f =="; \
	(cd $$d && TEXINPUTS=$(TEXINPUTS_) $(TEX) $$b >/dev/null 2>&1) || { echo "FAIL $$f"; ok=0; }; \
	grep -q 'SEAN-OK' $${f%.tex}.log 2>/dev/null && echo "  markers ok" || true; \
	done; [ $$ok = 1 ] && echo "ALL TEX OK" || exit 1
```

- [ ] **Step 2: Generalizzare `render`, `ref`, `regress` (cd nella dir del test + ref per-stanza)**

Sostituire i tre target con:

```make
render: ; @for f in $(RENDER_SRCS); do d=$$(dirname $$f); b=$$(basename $$f .tex); \
	(cd $$d && TEXINPUTS=$(TEXINPUTS_) $(TEX) $$b.tex >/dev/null 2>&1 && $(RENDER) $$b.pdf $$b >/dev/null 2>&1) \
	&& echo "  rendered $$b" || echo "  SKIP $$b (compile fail)"; done; echo "render done"

ref: render ; @for f in $(RENDER_SRCS); do d=$$(dirname $$f); b=$$(basename $$f .tex); \
	case "$$d" in fonts/*/test) r="$${d%/test}/ref" ;; *) r="test/ref" ;; esac; \
	mkdir -p $$r; cp $$d/$$b-1.png $$r/$$b.png 2>/dev/null && echo "  ref $$b" || true; done; echo "ref updated"

regress: render ; @ok=1; for f in $(RENDER_SRCS); do d=$$(dirname $$f); b=$$(basename $$f .tex); \
	case "$$d" in fonts/*/test) r="$${d%/test}/ref" ;; *) r="test/ref" ;; esac; \
	if [ -f $$r/$$b.png ]; then \
	  if cmp -s $$d/$$b-1.png $$r/$$b.png; then echo "  ok $$b"; \
	  else echo "  DIFF $$b"; ok=0; fi; \
	else echo "  (no ref) $$b"; fi; done; \
	[ $$ok = 1 ] && echo "REGRESS OK" || { echo "REGRESS FAIL"; exit 1; }
```

- [ ] **Step 3: Verificare che il motore sia ancora scoperto e verde**

Run: `make clean && make test`
Expected: termina con `ALL TEX OK`; nell'elenco `== ... ==` compaiono i test del motore (`test/place.tex`, …) e **non** ci sono ancora test in `fonts/*/test/`.

- [ ] **Step 4: Verificare la regressione visiva del motore + catalogo**

Run: `make regress`
Expected: `REGRESS OK` (i ref restano in `test/ref/`, incluso `catalog`).

- [ ] **Step 5: Commit**

```bash
git add Makefile
git commit -m "build: scoperta test e ref per-stanza (fonts/*/test)"
```

---

## Task 3: Font GS — `fonts/gs/font-gs.tex` + test di stanza

**Files:**
- Create: `fonts/gs/font-gs.tex`
- Create: `fonts/gs/test/font-gs.tex`
- Create: `fonts/gs/ref/font-gs.png` (via `make ref`)
- Modify: `Makefile:8` (RENDER_SRCS += `fonts/gs/test/font-gs.tex`)
- Modify: `README.md` (architettura: aggiungere `fonts/gs/` accanto a `fonts/wb/`)

**Interfaces:**
- Consumes: contratto del motore (`\seanfont`, `\seandeclaresymbol`, `\seanglyph`, `\seananchor`); helper di test `\seanassertglyph{<font>}{<id>}` (in `test/seantest.tex`); identità WB già dichiarate `gmic` (out), `lspk` (in), `hpf` (in,out).
- Produces: font `gs` con `parent=wb`; identità nuove `preamp` (in,out), `invert` (in,out), `lsf` (in,out), `comp` (in,out), `switch` (in,out); 8 glifi `gs/{gmic,lspk,hpf,preamp,invert,lsf,comp,switch}` con ancore `-in`/`-out` (e `-out` solo per gmic, `-in` solo per lspk).

- [ ] **Step 1: Scrivere il test di stanza che fallisce**

Create `fonts/gs/test/font-gs.tex` (i path `\input` sono root-relative, risolti via `TEXINPUTS=<root>`):

```latex
%!TEX TS-program = xelatex
\documentclass[tikz]{standalone}
\usepackage{circuitikz}      % serve a gs/hpf (highpass2)
\usetikzlibrary{sean}
\input{test/seantest.tex}
\input{fonts/gs/font-gs.tex}
\seanusefont{gs}
\begin{document}
% 1) esistenza degli 8 glifi (errore di compilazione se manca)
\seanassertglyph{gs}{gmic}\seanassertglyph{gs}{preamp}\seanassertglyph{gs}{switch}%
\seanassertglyph{gs}{hpf}\seanassertglyph{gs}{invert}\seanassertglyph{gs}{lsf}%
\seanassertglyph{gs}{comp}\seanassertglyph{gs}{lspk}%
% 2) catena reale: usare le ancore prova che -in/-out sono posate
\begin{tikzpicture}
  \pic[rotate=90]  (m) at (0,0)  {sean symbol=gmic};   % uscita verso destra
  \pic             (g) at (2,0)  {sean symbol=preamp};
  \pic             (h) at (4,0)  {sean symbol=hpf};
  \pic             (i) at (6,0)  {sean symbol=invert};
  \pic             (l) at (8,0)  {sean symbol=lsf};
  \pic             (c) at (10,0) {sean symbol=comp};
  \pic[rotate=-90] (s) at (12,0) {sean symbol=lspk};   % ingresso da sinistra
  \draw[seg/analog] (m-out) -- (g-in);
  \draw[seg/analog] (g-out) -- (h-in);
  \draw[seg/analog] (h-out) -- (i-in);
  \draw[seg/analog] (i-out) -- (l-in);
  \draw[seg/analog] (l-out) -- (c-in);
  \draw[seg/analog] (c-out) -- (s-in);
\end{tikzpicture}
\end{document}
```

- [ ] **Step 2: Eseguire il test e verificare che fallisca**

Run: `cd fonts/gs/test && TEXINPUTS=$(cd ../../.. && pwd): xelatex -interaction=nonstopmode -halt-on-error font-gs.tex; cd -`
Expected: FAIL — `\input{fonts/gs/font-gs.tex}` non trova il file (font-gs.tex non esiste ancora), oppure errore "glifo gs/... mancante".

- [ ] **Step 3: Scrivere `fonts/gs/font-gs.tex` (font + identità + 8 glifi)**

Create `fonts/gs/font-gs.tex` (glifi centrati sull'origine, derivati da `gs-graphics/lib/gs-simboli.tex`):

```latex
% Font GS — Giuseppe Silvi. La "mano" del diagramma del channel strip del timpano.
% Glifi centrati sull'origine, ancore in/out. Richiede circuitikz per hpf.
\seanfont{gs}{parent=wb}
\seanfontmeta{gs}{author=Giuseppe Silvi, year=2025, note=mano del diagramma del timpano}

% identità nuove (non nel canone WB) — dichiarate inline come nel bridge
\seandeclaresymbol{preamp}{in,out}
\seandeclaresymbol{invert}{in,out}
\seandeclaresymbol{lsf}{in,out}
\seandeclaresymbol{comp}{in,out}
\seandeclaresymbol{switch}{in,out}

% --- trasduttori ---
\seanglyph{gs}{gmic}{%
  \draw (0,0) circle (0.5\seanunit);
  \draw[very thick] (-0.5,0.5) -- (0.5,0.5);
  \draw (0,-0.5) -- (0,-1);
  \seananchor{out}{(0,-1)}}

\seanglyph{gs}{lspk}{%
  \draw (-90:0.5) -- (-210:0.5) -- (-330:0.5) -- cycle;
  \draw[very thick] (-0.25,-0.5) -- (0.25,-0.5);
  \draw[very thick] (-0.25,-0.6) -- (0.25,-0.6);
  \draw (0,-0.5) -- (0,-1);
  \seananchor{in}{(0,-1)}}

% --- filtro passa-alto: delega a circuitikz highpass2 (centrato) ---
\seanglyph{gs}{hpf}{%
  \draw (-0.75,0) to[highpass2] (0.75,0);
  \seananchor{in}{(-0.75,0)}\seananchor{out}{(0.75,0)}}

% --- preamp (gain): box + triangolo + freccia di guadagno ---
\seanglyph{gs}{preamp}{%
  \draw (-0.75,0) -- (0.75,0);
  \draw[fill=white,thick] (-0.5,-0.5) rectangle (0.5,0.5);
  \begin{scope}[shift={(-0.05,0)}]
    \draw[->,very thin,>={Latex[length=1mm, width=1mm]}] (-0.3,-0.3) -- (0.3,0.3);
    \draw[fill=white] (0:0.3) -- (120:0.3) -- (240:0.3) -- cycle;
  \end{scope}
  \seananchor{in}{(-0.75,0)}\seananchor{out}{(0.75,0)}}

% --- inversione di polarità: box + triangolo + pallino (Ø) ---
\seanglyph{gs}{invert}{%
  \draw (-0.75,0) -- (0.75,0);
  \draw[fill=white,thick] (-0.5,-0.5) rectangle (0.5,0.5);
  \begin{scope}[shift={(-0.1,0)}]
    \draw[fill=white] (0:0.3) -- (120:0.3) -- (240:0.3) -- cycle;
    \draw[fill=white] (0.325,0) circle (2pt);
  \end{scope}
  \seananchor{in}{(-0.75,0)}\seananchor{out}{(0.75,0)}}

% --- low-shelf: box + curva di shelving ---
\seanglyph{gs}{lsf}{%
  \draw (-0.75,0) -- (0.75,0);
  \draw[fill=white,thick] (-0.5,-0.5) rectangle (0.5,0.5);
  \draw[dotted,very thin] (-0.5,0) -- (0.5,0);
  \draw (-0.5,0.3) -- (-0.25,0.3) to[out=0,in=180] (0.25,0) -- (0.5,0);
  \seananchor{in}{(-0.75,0)}\seananchor{out}{(0.75,0)}}

% --- compressore: box + diagonale punteggiata + curva di transfer (knee) ---
\seanglyph{gs}{comp}{%
  \draw (-0.75,0) -- (0.75,0);
  \draw[fill=white,thick] (-0.5,-0.5) rectangle (0.5,0.5);
  \draw[dotted,very thin] (-0.5,-0.5) -- (0.5,0.5);
  \begin{scope}[shift={(-0.5,-0.5)}]
    \draw (0,0) -- (0.6,0.6) to[out=45,in=202] (0.75,0.7) -- (1,0.8);
  \end{scope}
  \seananchor{in}{(-0.75,0)}\seananchor{out}{(0.75,0)}}

% --- insert commutabile (solo meccanismo): in a sx, out a dx ---
\seanglyph{gs}{switch}{%
  \draw (-1.75,0) -- (-1.25,0) -- (-0.75,0.5);
  \draw[dotted] (-1.25,0) -- (-0.75,-0.5);
  \draw[->] (-1.0,0.25) arc (45:-40:0.375);
  \draw[fill] (-1.25,0) circle (2pt);
  \draw[fill] (-0.75,0.5) circle (2pt);
  \draw (-0.75,0.5) -- (0.75,0.5) -- (1.25,0) -- (1.75,0);
  \draw (0.75,-0.5) -- (1.25,0);
  \draw[fill=white] (-0.75,-0.5) circle (2pt);
  \seananchor{in}{(-1.75,0)}\seananchor{out}{(1.75,0)}}
```

- [ ] **Step 4: Eseguire il test e verificare che passi**

Run: `make test`
Expected: nell'elenco compare `== fonts/gs/test/font-gs.tex ==` con `  markers ok`, e il run termina con `ALL TEX OK`. (Gli 8 `SEAN-OK: glyph gs/...` sono nel log; la `tikzpicture` compila usando le ancore `-in`/`-out`.)

- [ ] **Step 5: Aggiungere il test alla regressione visiva e generare il ref**

In `Makefile`, aggiungere `fonts/gs/test/font-gs.tex` in coda a `RENDER_SRCS`:

```make
RENDER_SRCS = test/place.tex test/override.tex test/domains.tex test/font-wb.tex test/rotate.tex test/bridge.tex docs/catalog.tex fonts/gs/test/font-gs.tex
```

Run: `make ref`
Expected: compare `  ref font-gs`; viene creato `fonts/gs/ref/font-gs.png`.

- [ ] **Step 6: Aggiornare il README (architettura)**

In `README.md`, nel blocco architettura, sotto `fonts/`, aggiungere accanto a `wb/`:

```
fonts/
  wb/                        submodule → wb-tdme-simboli (font WB, glifi puri)
  gs/                        font GS (mano di Giuseppe Silvi): font-gs.tex + test/ + ref/
```

- [ ] **Step 7: Commit**

```bash
git add fonts/gs/font-gs.tex fonts/gs/test/font-gs.tex fonts/gs/ref/font-gs.png Makefile README.md
git commit -m "feat(gs): font GS con 8 glifi del channel strip del timpano"
```

---

## Task 4: Ridisegno del diagramma timpano in sintassi sean (validazione finale)

**Files:**
- Create: `fonts/gs/test/timpano.tex`
- Create: `fonts/gs/ref/timpano.png` (via `make ref`)
- Modify: `Makefile` (RENDER_SRCS += `fonts/gs/test/timpano.tex`)

**Interfaces:**
- Consumes: font `gs` di Task 3 (glifi + ancore); stili di connessione `seg/analog` (motore); `circuitikz` per `hpf`.
- Produces: un diagramma di canale completo del channel strip in sintassi sean, prova che la mano GS regge un diagramma reale. Routing/label/induttori restano a livello di diagramma.

- [ ] **Step 1: Scrivere il diagramma (un canale completo, etichettato)**

Create `fonts/gs/test/timpano.tex`. Riproduce un canale del channel strip
(mic → preamp → switch → hpf → invert → lsf → comp → lspk) nella nuova sintassi;
le sigle e l'altoparlante sono `\node`/pic a livello di diagramma. I 4 canali del
diagramma originale si ottengono ripetendo la macro `\gschannel` con prefissi/righe
diversi (ripetizione meccanica, mirror di `\channel` in
`gs-graphics/tempo/audio-chain/tempo-channel-strip-eng.tex`).

```latex
%!TEX TS-program = xelatex
\documentclass[tikz]{standalone}
\usepackage{circuitikz}
\usetikzlibrary{sean}
\input{fonts/gs/font-gs.tex}
\seanusefont{gs}
\begin{document}
\begin{tikzpicture}
  % --- un canale completo (prefisso pic = c1, riga y = 0) ---
  \pic[rotate=90] (c1mic) at (0,1.2)  {sean symbol=gmic};
  \node[font=\footnotesize, anchor=south] at (0,2) {LFU};
  \pic (c1pre) at (2,0)  {sean symbol=preamp};
  \pic (c1sw)  at (4,0)  {sean symbol=switch};
  \pic (c1hpf) at (6.5,0){sean symbol=hpf};
  \pic (c1inv) at (8.5,0){sean symbol=invert};
  \pic (c1lsf) at (10.5,0){sean symbol=lsf};
  \pic (c1cmp) at (12.5,0){sean symbol=comp};
  \pic[rotate=-90] (c1spk) at (15,-1.2) {sean symbol=lspk};
  \node[font=\footnotesize, anchor=north] at (15,-2) {LFU};
  % connessioni (very thin come i glifi; verso a carico dell'autore)
  \draw[seg/analog] (c1mic-out) -- (c1pre-in);
  \draw[seg/analog] (c1pre-out) -- (c1sw-in);
  \draw[seg/analog] (c1sw-out)  -- (c1hpf-in);
  \draw[seg/analog] (c1hpf-out) -- (c1inv-in);
  \draw[seg/analog] (c1inv-out) -- (c1lsf-in);
  \draw[seg/analog] (c1lsf-out) -- (c1cmp-in);
  \draw[seg/analog] (c1cmp-out) -- (c1spk-in);
\end{tikzpicture}
\end{document}
```

- [ ] **Step 2: Compilare e verificare che renda**

In `Makefile`, aggiungere `fonts/gs/test/timpano.tex` in coda a `RENDER_SRCS`.

Run: `make render`
Expected: compare `  rendered timpano` (nessun `SKIP timpano`).

- [ ] **Step 3: Verificare che il glob dei test lo raccolga (compila pulito)**

Run: `make test`
Expected: nell'elenco compare `== fonts/gs/test/timpano.tex ==` senza `FAIL`; il run termina con `ALL TEX OK`. (Non ha `\seanassert*`, quindi nessun marker `SEAN-OK` per questo file: è atteso — il `|| true` sul grep non fallisce.)

- [ ] **Step 4: Generare il ref di regressione**

Run: `make ref`
Expected: compare `  ref timpano`; viene creato `fonts/gs/ref/timpano.png`.

- [ ] **Step 5: Commit**

```bash
git add fonts/gs/test/timpano.tex fonts/gs/ref/timpano.png Makefile
git commit -m "test(gs): ridisegno del channel strip del timpano in sintassi sean"
```

---

## Note per l'esecutore

- Se un'ancora dichiarata non viene posata da un glifo, il test di Task 3 lo
  rivela in due modi: `\seancheckglyph` (opzionale) emette un *warning*, ma
  soprattutto la `tikzpicture` che disegna la catena **fallisce la compilazione**
  perché `(X-in)`/`(X-out)` non esistono → `make test` dà `FAIL`. È il segnale da
  inseguire.
- `hpf` richiede `circuitikz` nel documento: i due `.tex` di test lo caricano già.
  Se manca, l'errore è su `highpass2` sconosciuto.
- Il diagramma timpano (Task 4) è scientemente *un canale*: estendere a 4 canali +
  mix bus + induttori (ABBOTT/COSTELLO via `cute inductor`) + crossing è ripetizione
  meccanica fedele all'originale, fuori dal contratto del font.

## Fuori scope (bonifica futura dell'utente, da spec)

Deduplica `gmic`/`lspk`/`hpf` GS vs WB; identità di firma `emind`/`pedal`/`hsf`;
integrazione di `gs` nel catalogo `lib/catalog.tex`; migrazione del test WB nella
sua stanza; promozione di `fonts/gs` a submodule.
