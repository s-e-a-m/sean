# Font GS — porting dei simboli del diagramma timpano

**Data:** 2026-06-18
**Stato:** approvato (brainstorming) — in attesa di review dello spec

## Obiettivo

Portare in `sean` i simboli del diagramma del channel strip del timpano
(`gs-graphics/tempo/audio-chain/tempo-channel-strip-eng.tex`, macro in
`gs-graphics/lib/gs-simboli.tex`) come un nuovo **font `gs`** — la "mano" di
Giuseppe Silvi — accanto al font `wb` (Walter Branchi).

Decisione di rotta esplicita dell'utente: **ogni simbolo del diagramma diventa
un glifo GS adesso**; la *bonifica* (deduplica vs WB, eventuali identità di
firma come `emind`/`pedal`, integrazione nel catalogo) è rimandata e la farà
l'utente, anche perché i glifi WB sono ancora in lavorazione su issue.

## Contesto verificato

- Il contratto del font è `\seanglyph{font}{identità}{disegno-tikz}`; il glifo
  deve **posare le ancore** dichiarate nel vocabolario via `\seananchor{nome}{coord}`.
- La risoluzione con fallback (`\sean@resolveloop` in `lib/substrate.tex`) cerca
  nel font attivo e risale ai `parent`. Quindi `gs` con `parent=wb` **eredita
  tutto WB e vince solo dove ridisegna**. Deduplicare in futuro = *cancellare*
  un glifo GS ridondante; il fallback recupera quello WB. Zero rischio.
- Un file-font può dichiarare identità nuove inline con `\seandeclaresymbol`,
  come fa `lib/bridge-circuitikz.tex` con `phantom48`. Il canone WB
  (`lib/vocabulary-core.tex`) resta intoccato.
- I test si risolvono via `TEXINPUTS=<root>` con `\input` root-relative; una
  stanza `fonts/gs/test/font-gs.tex` compila identica a `test/font-wb.tex`.
- `test/seantest.tex` è l'helper condiviso del motore (definisce
  `\seanassertglyph`): resta in `test/`.
- I 45 artefatti in `test/` su disco sono già in `.gitignore` (`*.pdf`,
  `*.png` salvo `!test/ref/*.png`); git traccia solo 14 sorgenti `.tex` + ref.

## Classificazione dei segni del diagramma (validazione)

Regola del progetto: **circuitikz → WB → GS** (se non esiste sopra, lo scrivo in GS).

| Macro storica | Cos'è | Verdetto canonico | In questo porting |
|---|---|---|---|
| `\gmic` | microfono generico | WB `gmic` (≈ identico) | glifo `gs/gmic` (override; dedup dopo) |
| `\lspk` | altoparlante | WB `lspk` | glifo `gs/lspk` (override; dedup dopo) |
| `\hpf` | passa-alto (delega a `highpass2`) | circuitikz/WB | glifo `gs/hpf` (la tua resa via `highpass2`) |
| `\gain` | preamp (triangolo + freccia) | nuova → GS | glifo `gs/preamp`, identità nuova |
| `\invert` | inversione di polarità (Ø) | nuova → GS | glifo `gs/invert`, identità nuova |
| `\lsf` | low-shelf | nuova → GS | glifo `gs/lsf`, identità nuova |
| `\comp` | compressore (curva transfer) | nuova → GS | glifo `gs/comp`, identità nuova |
| `\switch` | insert commutabile | nuova → GS | glifo `gs/switch`, identità nuova |

**Fuori scope (routing/annotazione del diagramma, non "simboli" autoriali):**
dot di somma (WB `connopen`/`connclosed` → circuitikz `circ`/`ocirc`),
`jump crossing` (circuitikz), `cute inductor` ABBOTT/COSTELLO (circuitikz;
candidato firma `emind` per la bonifica futura), cornici e label testuali.

## Passo 0 — riordino dell'albero (pre-porting)

Prima del porting si pulisce la root per una crescita ordinata (appunto utente).
Solo rinomine, nessuno spostamento di motore:

- `doc/` → `docs/` (consolida i due nomi simili: `doc/catalog.tex` → `docs/catalog.tex`;
  `docs/` contiene già `superpowers/specs/`). Aggiornare `RENDER_SRCS` nel Makefile.
- `log/` → `logs/` (un solo file: `2026-06-18-bootstrap-architettura.md`).
- `lib/`, `test/`, `fonts/` **restano in root** (sono il cuore, non "utilità"; `fonts/`
  inoltre è vincolato dal path del submodule in `.gitmodules`).
- **Nessun `refs/` in root**: i riferimenti di regressione restano *per-stanza*
  (motore in `test/ref/`, font in `fonts/<nome>/ref/`). L'idea `refs/` dell'appunto
  è superata dalla scelta "stanza propria per font".

Root risultante: `docs/ fonts/ lib/ logs/ test/` + file (`Makefile`, `README.md`,
`tikzlibrarysean.code.tex`, `.gitignore`, `.gitmodules`).

## Architettura: "stanza propria per font"

Il motore resta condiviso; ogni font in-repo prende una stanza completa.

```
fonts/gs/
  font-gs.tex          # \seanfont{gs}{parent=wb} + meta + identità nuove + 8 glifi
  test/font-gs.tex     # asserzioni SEAN-OK + figura della catena
  ref/font-gs.png      # riferimento di regressione visiva della stanza
test/                  # MOTORE, condiviso: fallback, override, missing, place, …
  seantest.tex         # helper condiviso (resta qui)
  font-wb.tex          # TRANSITORIO: test d'integrazione WB, finché non si bonifica WB
```

**Decisione sul confine WB:** il submodule `fonts/wb` è "glifi puri"
(`font-wb-puro`); `test/font-wb.tex` è un test d'integrazione del *parent*
(usa `\usetikzlibrary{sean}`), quindi non può migrare nel submodule senza
sporcarne il contratto. La migrazione del test WB nella sua stanza è **bonifica
di WB** ed è differita. `test/font-wb.tex` resta in `test/` come stato
transitorio dichiarato. GS, essendo in-repo, ottiene la stanza completa subito.

## `fonts/gs/font-gs.tex` — contenuto

1. `\seanfont{gs}{parent=wb}`
2. `\seanfontmeta{gs}{author=Giuseppe Silvi, year=2025, note=mano del diagramma del timpano}`
3. Identità nuove (inline, alla maniera del bridge):
   ```latex
   \seandeclaresymbol{preamp}{in,out}
   \seandeclaresymbol{invert}{in,out}
   \seandeclaresymbol{lsf}{in,out}
   \seandeclaresymbol{comp}{in,out}
   \seandeclaresymbol{switch}{in,out}
   ```
4. 8 glifi `\seanglyph{gs}{…}{…}`, **ri-centrati sull'origine**, senza coordinate
   assolute e senza label (le label diventano `\node` a livello di diagramma),
   ciascuno con le ancore:

   | identità | ancore | resa (dalla macro storica, normalizzata) |
   |---|---|---|
   | `gmic` | `out` | cerchio + barra spessa in alto + stelo |
   | `lspk` | `in` | triangolo + doppia barra + stelo |
   | `hpf` | `in,out` | `to[highpass2]` (richiede circuitikz nel doc) |
   | `preamp` | `in,out` | box + triangolo + freccia di guadagno |
   | `invert` | `in,out` | box + Ø (triangolo + pallino) |
   | `lsf` | `in,out` | box + curva low-shelf |
   | `comp` | `in,out` | box + curva di transfer (knee) |
   | `switch` | `in,out` | meccanismo di insert commutabile, **senza** avvolgere altro segno |

   Nota porting: le macro storiche sono posizionali `{x}{y}{rot}{label}` e usano
   coordinate assolute; in sean il glifo è puro (centrato), la rotazione è
   per-istanza a carico di chi scrive, le label sono nodi del diagramma.

   Nota `switch`: la macro storica è di ordine superiore (avvolge un'altra
   macro). In sean i pic non prendono argomenti: `gs/switch` disegna **solo il
   meccanismo** con ancore `in/out`; ciò che si commuta lo posa l'autore del
   diagramma.

   Nota `hpf`: la resa storica delega a `highpass2` di circuitikz → il glifo
   `gs/hpf` richiede `\usepackage{circuitikz}` nel documento (come il bridge).

## Test — `fonts/gs/test/font-gs.tex`

- `\documentclass[tikz]{standalone}`, `\usetikzlibrary{sean}`,
  `\usepackage{circuitikz}` (per `hpf`).
- `\input{seantest.tex}`, `\input{fonts/gs/font-gs.tex}`, `\seanusefont{gs}`.
- `\seanassertglyph{gs}{<id>}` per ciascuna delle 8 identità → emette
  `SEAN-OK` se tutte le ancore dichiarate sono posate.
- Una `tikzpicture` che dispone la catena del channel strip (preamp → switch/hpf
  → invert → lsf → comp) come figura di regressione visiva.

## Makefile

Generalizzare la scoperta dei test da `test/*.tex` a
`test/*.tex` **+** `fonts/*/test/*.tex`. Ogni test risolve il proprio `ref/`
nella sua stanza (engine: `test/ref/`; gs: `fonts/gs/ref/`). Aggiornare
`RENDER_SRCS` per il rinomino `doc/catalog.tex` → `docs/catalog.tex` e aggiungere
`fonts/gs/test/font-gs.tex` (e `fonts/gs/test/timpano.tex`, vedi sotto). Il glob
del target `test` raccoglie automaticamente i test delle stanze.

## Validazione finale — ridisegno del diagramma timpano (appunto utente)

A porting completato, riscrivere il channel strip del timpano con la nuova
sintassi sean (`\pic ... {sean symbol=...}` + connessioni `seg/...`), font `gs`
attivo, come prova reale che la "mano" GS regge un diagramma intero. Vive nella
stanza GS come `fonts/gs/test/timpano.tex` con ref `fonts/gs/ref/timpano.png`,
ed entra in `RENDER_SRCS`. Le label (LFU/RFD/…), il routing (dot di somma,
crossing) e gli induttori restano a livello di diagramma (circuitikz/WB), come
da classificazione.

## Fuori scope (bonifica futura dell'utente)

- Deduplica `gmic`/`lspk`/`hpf` GS vs WB (cancellare i glifi ridondanti).
- Eventuali identità di firma: `emind` (induttore-trasduttore del timpano),
  `pedal` (pedale d'espressione), `hsf` (high-shelf).
- Integrazione di `gs` nel catalogo `lib/catalog.tex` (vista per-font + confronto).
- Migrazione del test WB nella sua stanza (dipende dalla bonifica del submodule).
- Promozione di `fonts/gs` a submodule/repo separato.

## Criteri di successo

1. `fonts/gs/font-gs.tex` compila e definisce font `gs` con `parent=wb`.
2. `make test` raccoglie `fonts/gs/test/font-gs.tex` e stampa `SEAN-OK` per
   tutte e 8 le identità GS.
3. Il font `wb` e i 13 test del motore restano invariati e verdi.
4. Cambiando font (`\seanusefont{gs}` ↔ `\seanusefont{wb}`) la stessa catena
   astratta rende i glifi della mano corrispondente; le identità non
   ridisegnate da GS ricadono su WB via fallback.
5. La root è riordinata (`docs/ fonts/ lib/ logs/ test/`) e tutti i test del
   motore + catalogo restano verdi dopo il rinomino.
6. Il diagramma del timpano è ridisegnato in sintassi sean con font `gs`
   (`fonts/gs/test/timpano.tex`) e compila.

# APPUNTI GS:

Prima di partire sistemare l'albero delle cartelle: abbiamo due doc e docs troppo simili, la cartella doc è di WB per cui prima di muoversi pulire la root e predisporre una crescita ordinata del repositorio.

Al termine del porting GS un test importante sarebbe provare a ridisegnare il diagramma del timpano con la nuova sintassi.

in root restano cartelle e font di utilità che devono stare in root
docs/
fonts/
logs/
refs/

