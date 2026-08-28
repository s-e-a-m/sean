# Log di sessione — 2026-08-28 — Design della pubblicazione web delle documentazioni

## Obiettivo
Decidere come pubblicare online, in continuità fra loro, le documentazioni di `sean`, `faust-libraries` e `seam-ltm`.
La domanda di partenza di Giuseppe era se la documentazione di `sean` potesse stare in continuità col sito `s-e-a-m.github.io`, e se il lavoro sulle pagine delle librerie fosse già online.

## Stato trovato
Il sito `s-e-a-m.github.io` è vivo (Jekyll, tema remoto `mmistakes/minimal-mistakes`, skin `dark`, Pages `legacy` su `master:/`).

Le due pagine delle librerie **erano già online** — `/faustlibraries/basic/` e `/faustlibraries/math/` rispondono 200 con il contenuto giusto.
Non si vedevano perché nessuna voce del menu `main:` in `_data/navigation.yml` le nomina: raggiungibili solo per URL diretto.

Trovato un secondo difetto, distinto: il repo `s-e-a-m/faust-libraries` ha GitHub Pages attivo e serve il proprio README col tema di default su `/faust-libraries/`.
Due indirizzi quasi identici per la stessa documentazione, con due identità visive.
Il path senza trattino era l'unico libero, perché fra project page e user site **vince la project page**.

Su `sean` e `seam-ltm` GitHub Pages è assente: i loro path sono liberi.

Verificato che `faust-libraries` genera già venti reference in `doc/build/` (via `doc/Makefile`, `faustlib2md.awk`, `svg-embed.py`) e che solo due sono state trasportate a mano nel sito.
Verificata la toolchain locale: `xelatex` (TeX Live 2026), `dvisvgm` 3.6, `pdftoppm`, `gawk`, `faust` 2.85.5, `python3`.

## Decisioni prese
1. **Hub unico** su `s-e-a-m.github.io`; GitHub Pages di repo spente.
2. **Trasporto con `make publish` locale** dal repo sorgente; il commit resta un gesto umano.
3. **`sean` pubblica una reference per segno**, coi font affiancati, generata da `lib/vocabulary-core.tex`.
4. **`seam-ltm` pubblica i sedici plugin come schede**; build e installazione restano nel README.
5. **L'URL è il nome del repo**: `/faust-libraries/`, `/sean/`, `/seam-ltm/`. `/faustlibraries/` sparisce, senza redirect (nessuno ci linka).

## Note tecniche emerse
Il vocabolario di `sean` è già in forma estraibile: `\seandeclaresymbol{id}{ancore} % descrizione` è una riga per identità, leggibile da un `awk` fratello di `faustlib2md.awk`.

Per i glifi conviene `dvisvgm` (SVG vettoriale, inlinabile) e non il PNG di `make render`, che resta al servizio di `make regress`.
Sul sito in skin `dark` i path neri su trasparente sarebbero invisibili: nel publish `fill`/`stroke` a `#000000` diventano `currentColor`.

`seam-ltm` è l'unico dei tre senza un registro: le sue tabelle sono prosa nel README, quindi va creato `doc/plugins.yml` prima di poter generare le schede.

## Azioni
- Scritta la spec in `docs/superpowers/specs/2026-08-28-pubblicazione-docs-seam-design.md`.
- Nessuna modifica a codice, `lib/`, `fonts/`, `test/`, `Makefile`: questa sessione è di solo design.

## Punti aperti
- Lingua delle descrizioni del vocabolario di `sean` sul sito: rinviata a una sessione dedicata.
- Il submodule `fonts/wb` punta ancora a GitLab via SSH: pubblicare la doc di un repo che nessuno può compilare è una promessa a metà, quindi la priorità del trasferimento a `s-e-a-m` sale.

## Esecuzione (stessa giornata)
Scritto il piano delle fasi 0-1 e poi eseguito per intero: `docs/superpowers/plans/2026-08-28-pubblicazione-fase01-sito-e-faust-libraries.md`.

Online e verificato: `/docs/`, `/faust-libraries/`, `/faust-libraries/basic/`, `/faust-libraries/math/` rispondono 200; il vecchio `/faustlibraries/basic/` risponde 404.
`/faust-libraries/` restituisce `<title>Faust Libraries - SEAM</title>`: è il sito a servirlo, non più la project page del repo.

Scoperta che ha corretto la spec: `doc/build/` non conteneva venti reference pronte, ma due.
Solo `seam.basic` e `seam.math` hanno funzioni documentate alla fonte; le altre diciotto producono pagine di soli titoli.
Introdotto un gate di copertura in `publish.sh`, e le diciotto sono diventate voci del `TODO.md` di `faust-libraries`.

Il repo `faust-libraries` non aveva `CLAUDE.md`, `TODO.md` né `logs/`: creati.
Il README del sito era ancora il boilerplate del tema Minimal Mistakes: riscritto.
Rifinitura della sidebar aperta come issue `s-e-a-m/faust-libraries#32`.

Restano da fare le fasi 2 (`sean`) e 3 (`seam-ltm`), che avranno piani separati.

## Chi
**Chi:** Claude (agente), su indicazione e con le decisioni di Giuseppe.
