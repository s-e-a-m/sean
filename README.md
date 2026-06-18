# sean — Sustained ElectroAcoustic Notation

`sean` è una libreria TikZ per scrivere **diagrammi a blocchi della musica elettroacustica come partiture**: catene di segni (microfoni, amplificatori, filtri, altoparlanti…) connessi tra loro. È un *sistema notazionale autonomo* che interopera con [circuitikz](https://ctan.org/pkg/circuitikz) ma non ne dipende.

Nasce dalla trascrizione dei simboli di Walter Branchi, *Tecnologie della musica elettronica* (1976), estesi all'uso contemporaneo.

## Idea centrale: frase vs font

Come in un editor di testo si cambia il *font* lasciando la *frase* invariata, qui:

- **La frase** = il diagramma astratto: identità di segno (`gmic`, `amp`, `lspk`…) collegate per nome. Indipendente dallo stile.
- **Il font** = lo stile di un autore/tradizione (WB, GS, DT, …) che *disegna* quei segni. Cambi font → stessa catena, segno diverso.
- **L'ereditarietà** = un font può dichiarare un genitore (`gs` con `parent=wb`): ridisegna solo ciò che vuole, il resto **ricade** sul genitore — "come se la scrittura non si fosse interrotta".

Distinzione *carattere vs glifo* (à la Unicode): il **vocabolario astratto** è l'encoding condiviso; ogni **font** fornisce i glifi.

## Architettura

```
tikzlibrarysean.code.tex     loader (\usetikzlibrary{sean})
lib/
  substrate.tex              vocabolario, ancore, unità, macchina font,
                             fallback/override, stili di dominio, provenienza, errori
  vocabulary-core.tex        identità del canone WB (8 segni)
  catalog.tex                catalogo auto-generato (vista per-font + confronto)
  bridge-circuitikz.tex      circuitikz registrato come font
fonts/
  wb/                        submodule → wb-tdme-simboli (font WB, glifi puri)
  gs/                        font GS (mano di Giuseppe Silvi): font-gs.tex + test/ + ref/
docs/
  catalog.tex                documento-catalogo
  superpowers/               spec e piani (brainstorming/writing-plans)
test/                        test (compilazione + asserzioni SEAN-OK) + ref/ (regressione visiva)
logs/                        log di sessione (uno per data)
Makefile                     test / render / ref / regress
```

Il **canone WB** vive in un repo separato ([`wb-tdme-simboli`](https://gitlab.com/giuseppesilvi/wb-tdme-simboli), branch `font-wb-puro`) agganciato come submodule: contiene *solo glifi*, scritti contro il contratto definito qui in `lib/substrate.tex`.

## Uso

```latex
\documentclass[tikz]{standalone}
\usetikzlibrary{sean}
\input{fonts/wb/font-wb.tex}   % carica il font WB
\seanusefont{wb}
\begin{document}
\begin{tikzpicture}
  \pic (m) at (0,0) {sean symbol=gmic};      % microfono generico
  \pic (a) at (3,0) {sean symbol=ampgen};    % amplificatore
  \pic (s) at (6,0) {sean symbol=lspk};      % altoparlante
  \draw[seg/analog] (m-out) -- (a-in);
  \draw[seg/analog] (a-out) -- (s-in);
\end{tikzpicture}
\end{document}
```

Compilazione: **XeLaTeX** (richiede il font Datalegreya e `circuitikz` per il ponte). Esempio: `TEXINPUTS=<root_di_sean>: xelatex documento.tex`.

### Orientamento e rotazione

Ogni segno ha un **puntamento naturale** (l'orientazione con cui è disegnato, quella mostrata nel catalogo). La rotazione è **per-istanza e a carico di chi scrive il diagramma** — non c'è (di proposito) alcuna rotazione automatica: lo stesso oggetto può servire in verticale e in orizzontale a seconda del routing (es. microfoni divisi in zone).

```latex
\pic            (m0) at (0,0) {sean symbol=gmic};   % naturale
\pic[rotate=90] (m1) at (3,0) {sean symbol=gmic};   % ruotato; l'ancora m1-out segue la rotazione
\draw[seg/analog] (m1-out) -- (a-in);               % collegamento (peso di default, vedi sotto)
```

Le **ancore seguono la rotazione** (sono coordinate interne al `pic`), quindi i collegamenti restano coerenti. I collegamenti `seg/*` sono al **peso di default**, allineato al tratto dei glifi GS; l'omologazione del peso per il font WB (glifi `very thin`) è tracciata in `TODO.md`. Le **frecce di direzione** non stanno né nei glifi né nei collegamenti per default: se servono, le aggiunge l'utente in modo esplicito (`->`).

## Riferimento dei comandi

| Comando | Scopo |
|---|---|
| `\seandeclaresymbol{id}{anchorlist}` | registra un'identità nel vocabolario (es. `{amp}{in,out}`) |
| `\seanglyph{font}{id}{corpo}` | definisce il glifo `id` per un font |
| `\seananchor{nome}{coord}` | dentro un glifo, posa un'ancora (referenziabile come `<picname>-<nome>`) |
| `\seanfont{nome}{parent=...}` | dichiara un font con eventuale genitore (fallback) |
| `\seanfontmeta{font}{author=...,year=...,note=...}` | provenienza del font |
| `\seanusefont{nome}` | imposta il font attivo |
| `\pic (n) {sean symbol=id}` | posa un segno; `(n-anchor)` per connettersi |
| `\pic[sean font=f] (n) {sean symbol=id}` | override del font per quel segno |
| `\seancheckglyph{font}{id}` | verifica che il glifo posi tutte le ancore dichiarate |
| `\seancatalogfont{font}` / `\seancatalogcompare{f1,f2,…}` | catalogo per-font / confronto |

Stili di connessione (dominio del segnale): `seg/analog`, `seg/digital`, `seg/control`; confini `hw`, `sw`. Unità di griglia: `\seanunit` (default 1cm).

Gestione errori: identità non dichiarata → errore; identità dichiarata ma senza glifo nel font (né nei genitori) → **segnaposto tratteggiato** + warning.

## Build & test

```
make test       # compila i test, verifica i marker SEAN-OK
make render     # produce PDF/PNG dei test visivi e del catalogo
make regress    # confronta i render coi riferimenti in test/ref/ (DIFF se cambiati)
make ref        # aggiorna i riferimenti (solo se le modifiche visive sono volute)
```

## Stato

Architettura e convenzioni complete e collaudate. **Font WB: trascrizione integrale dell'Appendice 6 (37 segni)** — sorgenti/segni base, misura, generatori, filtri, modulatori, registrazione/lettura, trasduttori. Font `circuitikz`: `ampgen`, `phantom48`, e i filtri `hpf/lpf/bpf/bsf` (riuso dei bipoli circuitikz).

`connopen`/`connclosed` delegano a circuitikz (`ocirc`/`circ`): un documento che li usa deve caricare `circuitikz`.

**Da verificare con la fonte cartacea** (lettura interpretativa della scansione): i motivi interni dei filtri (`~`/linee per passa-basso/alto/banda/soppressore), la sagoma del CRT in `scope`, le testine (`headplay/rec/erase`), l'eventuale cerchio nel `gensin`.

**Prossimi passi** (cicli successivi): font GS (timpano aumentato — `lsf`, `comp`, `invert`, `hpf` circuitikz) e altri contributori; diagramma della catena elettroacustica per il paper CIM; trasferimento a SEAM (Sustained ElectroAcoustic Music) con nome/remote definitivi e un **manuale circuitikz** (circuitikz è notazione di partitura a pieno titolo — es. i circuiti degli induttori del timpano).

## Licenza

Da definire prima del trasferimento a SEAM.
