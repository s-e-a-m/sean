# Log di sessione — 2026-06-18 — Bootstrap architettura sean

## Obiettivo
Creare la libreria `sean` (Sustained ElectroAcoustic Notation) implementando il design
*architettura + convenzioni* (spec e piano in `wb-tdme-simboli/docs/superpowers/`, branch
`design-libreria-notazione`), e convertire `wb-tdme-simboli` in font WB puro.

## Esito
Completati 13 task in TDD adattato a LaTeX (compila-fallisce → implementa → compila-passa →
render → commit). Verifica finale: `make test` = `ALL TEX OK`, `make regress` = `REGRESS OK`.

## Decisioni di design recepite (dal brainstorming)
- Sistema notazionale **autonomo** che interopera con circuitikz (non sua estensione).
- Modello **frase vs font**: diagramma astratto indipendente dallo stile; autori = font; submodule = font.
- Priorità **infrastruttura durevole** (SEAM) sopra l'artefatto con scadenza.
- **Edizione critica**: canone WB fedele su un substrato/apparato condiviso.
- **Due repo**: `wb-tdme-simboli` = solo glifi WB (seme); ombrello `sean` = substrato + estensioni
  + catalogo, con WB come submodule a commit fisso.
- Fallback tra font + **override per-segno** opt-in. circuitikz **come font**. Domini come stili
  di linea. Provenienza per glifo. Catalogo auto-generato con vista confronto-font.
- Sostrato L0 nell'ombrello → WB non si compila da solo (è testo-fonte; l'ombrello è la lettura).

## Cosa è stato costruito
- `lib/substrate.tex`: vocabolario (`\seandeclaresymbol`), ancore (`\seananchor`), unità
  (`\seanunit`), glifi (`\seanglyph`), font+parent (`\seanfont`), font attivo (`\seanusefont`),
  risoluzione con fallback (`\seanresolve`), pic `sean symbol`, override `sean font`, segnaposto
  + warning, errore identità sconosciuta, conformità ancore (`\seancheckglyph`), stili dominio,
  provenienza (`\seanfontmeta`), accumulo `\sean@allsymbols`.
- `lib/vocabulary-core.tex`: 8 identità del canone (gmic cmic kmic rlev lspk girad indliv ampgen).
- `lib/catalog.tex`: `\seancatalogfont`, `\seancatalogcompare`.
- `lib/bridge-circuitikz.tex`: font `circuitikz` (ampgen delegato; phantom48 da 48v.tex, scalato).
- `fonts/wb` (submodule → wb-tdme-simboli@font-wb-puro): `font-wb.tex` con gli 8 glifi e ancore.
- `doc/catalog.tex`, suite `test/`, `Makefile` (test/render/ref/regress), `test/ref/` (6 PNG).

## Trappole TeX risolte
1. **Catcode di `@`**: gli helper di test (`test/seantest.tex`) referenziano macro interne
   `\sean@...`; nei documenti `@` è "other" → vanno avvolti in `\makeatletter…\makeatother`.
   Sintomo iniziale: `\sean@resolved` letto come `\sean`+`@resolved` (errore `'esolved'`).
2. **`\pgfmathsetmacro` dentro `\foreach` è locale** al gruppo dell'iterazione e si azzera →
   tutti i glifi del catalogo finivano a (0,0). Soluzione: contatore nativo `count=\r from 0`.
3. **Separatore del nome-pic**: `\coordinate (-out)` dentro un pic chiamato `(m1)` produce
   `m1-out` (verificato empiricamente, non assunto).
4. Conflitto target `make test` vs cartella `test/` → `.PHONY`; escluso l'include `seantest.tex`
   dal loop; `phantom48` enorme (coordinate legacy fino a 12) → normalizzato a cella (scale 0.12).

## Stato repo a fine sessione
- `sean`: locale, branch `main`, 16 commit, **nessun remote** (transfer a SEAM = futuro).
- `wb-tdme-simboli`: branch `font-wb-puro` (font WB) e `design-libreria-notazione` (spec+piano)
  pushati su origin; `main` invariato (vecchia struttura). Branch non mergiati (decisione utente).

## Commit (sean, in ordine)
- 9fff3cd bootstrap (loader, substrato, harness, smoke)
- a78ed4e vocabolario astratto
- 5272959 glifi, font con parent, fallback
- 3f0d1f2 pic 'sean symbol' + ancore
- 094b0bd untrack artefatti di build
- 5b30e4e segnaposto + errori
- 6212b14 conformità ancore
- eede0ad stili di dominio
- 71cf04e override font per-segno
- ca428b1 provenienza
- 06fc416 vocabolario canone WB
- 1986e36 submodule fonts/wb + test render
- a76058a circuitikz come font (phantom48)
- 701fb53 catalogo auto-generato
- 114313a regressione visiva
- 4af673b ignora .DS_Store

## Addendum — checkpoint di revisione (stesso giorno)
Osservazioni utente sui PDF, e relative azioni:
- **Datalegreya perso nel catalogo**: il font non era portato nell'ombrello → creato `lib/style.tex`
  (fontspec + Datalegreya), `\input` in `doc/catalog.tex`. La libreria resta font-agnostica.
- **PDF degeneri** (smoke/vocabulary/vocab-core/fallback/provenance/conformance): tikzpicture
  vuoto → pagina ~0 → crash di Finder/Quick Look. Aggiunto un nodo minimo: pagine valide.
- **Frecce nei glifi**: osservazione **ritirata** dall'utente dopo aver riguardato i disegni di
  Branchi — le frecce sono parte del font, restano. Nessuna modifica ai glifi.
- **Orientamento/rotazione**: niente rotazione automatica (un oggetto può servire sia verticale
  sia orizzontale a seconda del routing). Ogni segno ha il suo puntamento naturale; l'utente
  ruota per-istanza con `\pic[rotate=...]` (le ancore, interne al pic, seguono la rotazione —
  verificato). Esempio `font-wb` riscritto come catena orizzontale onesta; aggiunto `test/rotate.tex`
  (coperto da regressione) e nota nel README. Le frecce di flusso le aggiunge l'utente sul collegamento.
- Riferimenti di regressione riallineati (`make ref`). Commit: 585f38f, 4ab0b99, fb331dd.

## Addendum — trascrizione integrale Appendice 6 (stesso giorno)
- Scansione `resources/WB-TDME-SIMBOLI.pdf` giudicata sufficiente (no nuova foto).
- Aggiunti i **29 simboli mancanti** → font WB completo a **37** (vocabolario in `lib/vocabulary-core.tex`,
  glifi in `fonts/wb/font-wb.tex`, ora con helper DRY `\sean@wb{mod,gen,filt}` sotto `\makeatletter`).
- **Regola di riuso applicata anche a WB**: "se circuitikz ha un simbolo *uguale al cartaceo*, si usa,
  non si rigenera". Audit: match identici rari (WB è notazione idiosincratica). Riuso effettivo:
  `connopen`/`connclosed` → `ocirc`/`circ`. Nel **font circuitikz** aggiunti `hpf/lpf/bpf/bsf`
  (bipoli `highpass2`/`lowpass2`/`bandpass`/`bandstop`) — riuso, non ridisegno.
- Contemporanei del timpano (`lsf`, `comp`, `invert`, `hpf`-circuitikz) → **font GS**, ciclo dedicato dopo.
- Nota: nel repo finale (SEAM) andrà un **manuale circuitikz** (per l'utente lo schematico elettrico è partitura).
- Trappola risolta: `phantom48` (circuitikz) a coordinate assolute grandi → "Dimension too large".
  Fix: il catalogo rende ogni cella come **mini-tikzpicture dentro un nodo** (circuitikz disegna vicino all'origine).
- DA VERIFICARE con la fonte: motivi interni dei filtri, CRT di `scope`, testine, cerchio di `gensin`.

## Prossimi passi
Verifica umana del catalogo dei 37 segni; poi font GS (timpano), diagramma Lazzaro per il CIM,
trasferimento a SEAM (+ manuale circuitikz).
