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

## Prossimi passi
Checkpoint di revisione visiva umana in corso (sfogliare `doc/catalog.pdf` ecc., eventuali
ritocchi a mano). Poi, su modello `sean`: trascrizione integrale dei simboli dal libro WB,
font GS (timpano), diagramma Lazzaro per il CIM, trasferimento a SEAM.
