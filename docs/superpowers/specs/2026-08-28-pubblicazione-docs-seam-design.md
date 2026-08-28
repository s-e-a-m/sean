# Pubblicazione della documentazione di sean, faust-libraries e seam-ltm

Data: 2026-08-28.
Intervento: Giuseppe Silvi, con l'agente (Claude Code).
Stato: design approvato, non ancora implementato.

## Il problema

Tre progetti dell'organizzazione `s-e-a-m` hanno documentazione che merita di stare online e non ci sta, o ci sta male.

`faust-libraries` genera già venti reference in `doc/build/` ma solo due sono pubblicate.
`sean` documenta il proprio vocabolario in un catalogo PDF, invisibile dal web.
`seam-ltm` ha un README completo che vive solo su GitHub.

Il sito `s-e-a-m.github.io` esiste, è vivo, ed è costruito su Jekyll con il tema remoto `mmistakes/minimal-mistakes` in skin `dark`.
Ha già una collection `libraries` con le reference di `seam.basic.lib` e `seam.math.lib`.

Al momento del design la situazione presenta due difetti distinti, spesso confusi tra loro.

**Le pagine esistenti sono orfane.**
`/faustlibraries/basic/` e `/faustlibraries/math/` rispondono 200 e sono corrette, ma nessuna voce di `_data/navigation.yml` sotto `main:` le nomina.
Sono raggiungibili solo digitando l'URL: esistono e non si trovano.

**Due canali di pubblicazione si contendono lo stesso progetto.**
Il repository `s-e-a-m/faust-libraries` ha GitHub Pages attivo (`legacy`, sorgente `master:/`) e serve il proprio README con il tema di default su `s-e-a-m.github.io/faust-libraries/`.
Il sito serve la reference curata su `s-e-a-m.github.io/faustlibraries/`.
Due indirizzi quasi identici, due identità visive, una sola documentazione.

Il nome senza trattino non era una scelta di stile: era l'unico path libero, perché quando una project page e il user site collidono, **la project page ha la precedenza**.

## Decisioni prese

1. **Hub unico.** Tutte e tre le documentazioni vivono sul sito `s-e-a-m.github.io`; le GitHub Pages di repo restano spente.
2. **Trasporto con `make publish` locale.** Ogni repo genera e copia nel sito; il commit lo fa una persona, non un'automazione.
3. **sean pubblica una reference per segno**, con i font affiancati, generata dal registro e non scritta a mano.
4. **seam-ltm pubblica i sedici plugin come schede**; build, SDK e installazione restano nel README, accanto al codice.

## Architettura

### Routing: l'URL è il nome del repo

    s-e-a-m.github.io/faust-libraries/          indice della suite
    s-e-a-m.github.io/faust-libraries/basic/    seam.basic.lib   (sba)
    s-e-a-m.github.io/faust-libraries/math/     seam.math.lib    (sma)
    s-e-a-m.github.io/sean/                     indice + reference per segno
    s-e-a-m.github.io/seam-ltm/                 indice + sedici schede plugin

Un solo principio, senza eccezioni da ricordare: chi legge l'URL sa quale repository aprire, e viceversa.
`/faustlibraries/` sparisce.

L'unica eccezione è la pagina hub `/docs/`, che non corrisponde a nessun repository perché è l'indice dei tre.
È un'eccezione dichiarata, non un'incoerenza: nessun repo può rivendicare quel path.

La regola regge **solo finché GitHub Pages di repo resta spento** su tutti e tre.
Chiunque lo riattivi — un click nelle impostazioni, un default dell'organizzazione — ruba il path al sito, e lo fa in silenzio: le pagine del sito verrebbero costruite, caricate e mai servite, senza alcun errore.
Per questo la regola va scritta nel `CLAUDE.md` di ciascun repo.

### Migrazione di faust-libraries: l'ordine è obbligato

1. Spegnere Pages sul repo: `gh api -X DELETE repos/s-e-a-m/faust-libraries/pages`.
2. Cambiare il permalink della collection in `_config.yml` e i due `permalink:` nel front matter di `basic.md` e `math.md`.
3. Pubblicare: le pagine tornano vive al nuovo indirizzo, questa volta servite dal sito.
4. Aggiungere `/faust-libraries/index.md`, l'indice della suite, che sostituisce ciò che la vecchia project page faceva male.

Invertire i primi due passi significa debuggare per mezz'ora un sito che funziona.

I vecchi URL `/faustlibraries/basic|math/` non ricevono redirect.
Non sono mai stati raggiungibili dal menu, quindi nessuno ci linka: la decisione è consapevole.

### Le tre collection

    collections:
      libraries: { output: true, permalink: /faust-libraries/:path/ }
      sean:      { output: true, permalink: /sean/:path/ }
      ltm:       { output: true, permalink: /seam-ltm/:path/ }

Le cartelle sorgenti sono `_libraries/`, `_sean/`, `_ltm/`.

Il nome della collection non coincide con l'URL, ed è voluto.
Liquid non gestisce i trattini negli identificatori (`site.seam-ltm` non si scrive), quindi il nome interno resta corto e senza trattini, mentre il permalink segue la regola pubblica.

Ogni collection prende il proprio blocco in `defaults`, sul modello di quello che già funziona per `libraries`: `layout: single`, `author_profile: false`, `toc: true`, e la propria `sidebar: nav:`.

### Navigazione

Al `main:` di `navigation.yml` si aggiunge **una sola voce**, `Docs`, che porta alla pagina hub `/docs/`.
Non tre voci: `minimal-mistakes` non ha menu a tendina nel masthead, e sette voci in fila affollano la barra.

`/docs/` è una pagina scritta a mano, breve: tre blocchi, uno per progetto, con una riga su cos'è e il link alla sua reference.
È il punto in cui la continuità tra i progetti diventa visibile, e il posto naturale per il rimando incrociato fra `lr2xhgr` in Faust e **LR2XHGR** in VST3 — lo stesso metodo in due implementazioni.

Le tre sidebar interne (`libraries:`, `sean:`, `ltm:`) sono gli indici di ciascuna reference.

Un solo file è scritto da tutti e tre i repo: `_data/navigation.yml`.
Si gestisce con blocchi delimitati da marker, uno per repo:

    # BEGIN libraries (generato da faust-libraries — non modificare a mano)
    libraries:
      - title: "Library Reference"
        children: [...]
    # END libraries

Ogni `publish` sostituisce solo il proprio blocco e non guarda gli altri.
Regge il caso che conta: venti librerie pubblicate aggiornano la sidebar senza incollare venti voci a mano.

### Asset

Convenzione `assets/<nome-repo>/`, popolata dal `make publish` del repo corrispondente.

In pratica la usa solo `seam-ltm`, con i sedici screenshot in `assets/seam-ltm/img/`.
`faust-libraries` non la usa: `svg-embed.py` inlina i diagrammi Faust dentro il Markdown, e la pagina resta autoportante.
`sean` adotta la stessa strategia con i propri glifi.

### Provenienza

Ogni pagina generata porta tre campi che il suo `make publish` scrive da sé:

    generated_from: faust-libraries
    generated_rev: 31d410c
    generated_at: 2026-08-28

Il layout li mostra in fondo alla pagina, in piccolo.
Costa un `git rev-parse --short HEAD` per repo e risponde alla domanda che altrimenti nessuno sa più risolvere: questa pagina corrisponde a quale stato del codice?

I file generati stanno in un repository dove tutto il resto si scrive a mano.
Prima o poi un refuso verrà corretto direttamente in `_libraries/basic.md`, e il `publish` successivo lo cancellerà senza dire niente.
Contromisura minima: un commento come prima riga dopo il front matter.

    <!-- GENERATO — non modificare qui: la fonte è faust-libraries/src/seam.basic.lib -->

Non impedisce nulla, ma mette l'avviso dove si guarderà.

## I tre `make publish`

### Contratto comune

Quattro regole, uguali per tutti e tre, come convenzione documentata e non come codice condiviso.

1. **Genera, poi trasporta.** Il `publish` non duplica la logica di generazione: chiama i target che già esistono e si occupa solo di front matter e copia.
2. **Scrive solo nella propria cartella**: la sua collection, il suo `assets/<repo>/`, il suo blocco marcato in `navigation.yml`. Mai altrove.
3. **Non committa e non pusha.** Lascia il working tree del sito sporco: il controllo editoriale resta un gesto umano.
4. **Timbra la provenienza**, con i tre campi di cui sopra.

Ogni Makefile dichiara `SITE ?= <default>` e si ferma con un messaggio utile se la cartella non esiste, suggerendo `make publish SITE=/percorso/al/sito`.

I tre repo non vivono nello stesso albero.
`faust-libraries` e `seam-ltm` stanno in `github/seam/librerie/`, e per loro il default relativo `../../blog/s-e-a-m.github.io` funziona.
`sean` sta in `gitlab/gs/`, in un albero diverso: il suo default è assoluto, `$(HOME)/Documents/github/seam/blog/s-e-a-m.github.io`.

### faust-libraries

Quasi tutto esiste già.
`make doc` produce `doc/build/seam.*.md` con gli SVG inline; `doc/scripts/makeindex.awk` produce l'indice.

Serve un solo pezzo nuovo, `doc/scripts/publish.sh`.
Per ogni `doc/build/seam.NAME.md` deriva il nome breve, antepone il front matter (`title: "Faust Libraries · NAME"`, `permalink: /faust-libraries/NAME/`, `toc: true`, provenienza) e scrive in `$(SITE)/_libraries/NAME.md`.
Più `index.md` dall'indice generato.

Il salto è da due librerie a venti, senza lavoro manuale: è già tutto in `doc/build/`, semplicemente non è mai stato trasportato.

### sean

Due pezzi da scrivere, nessuna toolchain nuova.
Sulla macchina di lavoro sono presenti `xelatex` (TeX Live 2026), `dvisvgm` 3.6, `pdftoppm`, `gawk`, `faust` e `python3`.

**Il rendering dei glifi.**
Un target `svg` genera un `.tex` `standalone` con una pagina per coppia (identità, font), iterando su `\sean@allsymbols` come già fa `\seancatalogcompare`.
Lo compila con `xelatex -no-pdf` e passa l'`.xdv` a `dvisvgm`, una pagina per file: una sola compilazione per tutti i glifi.

I glifi sono TikZ, cioè vettoriali all'origine.
`make render` li appiattisce in PNG a 120 dpi perché quel PNG serve al confronto binario di `make regress`: ottimo per la regressione, sbagliato per il web, dove un segno notazionale si sgrana appena si ingrandisce.
Quindi due target distinti sullo stesso sorgente: **PNG per la regressione, SVG per la pubblicazione**.
`make render`, `make ref` e `make regress` non si toccano.

**L'estrattore.**
Un `awk` su `lib/vocabulary-core.tex`, fratello di `faustlib2md.awk`, ricava da ogni riga le tre colonne.

    \seandeclaresymbol{gmic}{out}      % microfono generico
    → identità: gmic | ancore: out | descrizione: microfono generico

Raggruppa per le sezioni già segnate dai commenti nel file (`% --- generatori ---`, `% --- filtri ---`) e inlina accanto a ciascuna identità gli SVG di ogni font.
Il risultato è la tabella con WB e GS affiancati: il registro è già la documentazione, mancava chi lo leggesse.

**Il colore.**
Il sito è in skin `dark`.
Gli SVG di Faust si portano dietro un `<rect fill:#ffffff>` e restano leggibili su qualsiasi tema; i glifi prodotti da `dvisvgm` sono path neri su trasparente, e su fondo scuro sarebbero invisibili.
La contromisura è una sostituzione nel publish: nei path generati, `fill` e `stroke` a `#000000` diventano `currentColor`, e il glifo prende il colore del testo che lo circonda.
Per un sistema notazionale è anche la scelta concettualmente giusta: un segno è dell'inchiostro del testo in cui sta.

**Il controllo sul submodule.**
Se `fonts/wb/` è vuoto, cioè il submodule non è inizializzato, il target si ferma con un messaggio esplicito.
Non deve generare una tabella con metà colonne vuote.

**La lingua.**
La cornice della pagina (cos'è sean, frase vs font, come si legge la tabella) è in inglese, come il resto del sito.
Le descrizioni dei segni escono in fase 1 così come stanno nel sorgente, in italiano, perché vengono dall'Appendice 6 di Branchi.
La revisione terminologica è rinviata a una sessione dedicata e va tracciata in `TODO.md`: non fa parte di questo lavoro.

### seam-ltm

Qui c'è un passo che gli altri due non richiedono.

`faust-libraries` e `sean` hanno un registro: i `.lib` con i commenti strutturati, `vocabulary-core.tex` con una riga per identità.
In entrambi i casi la fonte della documentazione è già dati, e basta leggerla.
`seam-ltm` ha come unica fonte le tabelle Markdown del README, cioè prosa formattata, scritta per essere letta e non per essere estratta.
Un parser costruito su quel file si rompe alla prima riformattazione.

Si crea quindi `doc/plugins.yml`: sedici voci con nome, I/O, famiglia, descrizione, screenshot e il rimando alla libreria Faust corrispondente dove esiste (`m2xhgr`, `lr2xhgr`).
È l'equivalente di `vocabulary-core.tex` per i plugin.

Da quel registro si generano **due** cose: le schede in `$(SITE)/_ltm/` e le tabelle dei plugin dentro il README del repo.
Entrambi i generatori si scrivono subito, non uno adesso e uno poi: il README va comunque letto riga per riga per estrarne i dati, e farlo due volte costa più che farlo una.
Con una sola fonte, sito e README non possono divergere.

Gli screenshot si copiano da `docs/img/` a `assets/seam-ltm/img/`.

## Fasi

**Fase 0 — la pulizia, senza scrivere un generatore.**
Spegnere Pages su `faust-libraries`, spostare il permalink, aggiungere la voce `Docs` e la pagina hub `/docs/`.
Le due pagine esistenti diventano raggiungibili, all'indirizzo giusto, dentro un percorso di navigazione.
È la fase con il miglior rapporto fra valore e lavoro, e va per prima perché libera il path che le altre useranno.

**Fase 1 — `faust-libraries`.**
Solo `publish.sh`: `doc/build/` è già pieno.

**Fase 2 — `sean`.**
Target `svg`, estrattore `awk`, `currentColor`, pagina reference.
È la fase con più codice nuovo.

**Fase 3 — `seam-ltm`.**
Registro `doc/plugins.yml`, i due generatori, gli screenshot.

Ogni fase finisce online e utile da sola: fermandosi dopo una qualsiasi, il sito resta in uno stato coerente.

## Verifica

Il sito ha `Gemfile` e `.ruby-version`: la verifica è locale prima del push, con `bundle exec jekyll serve`.

Per ogni fase, tre controlli.

- **Routing.** L'URL previsto risponde 200 e mostra il titolo giusto. In fase 0 vale anche il contrario: `/faustlibraries/basic/` deve dare 404, prova che la migrazione è avvenuta e non raddoppiata.
- **Navigazione.** La voce esiste nel menu, la sidebar elenca le pagine della collection, `/docs/` linka tutte e tre le reference.
- **Rendering.** Gli SVG si vedono; per sean si vedono **in entrambe le skin**, chiaro e scuro.

Per sean resta in piedi la rete esistente: `make regress` continua a confrontare i PNG contro `test/ref/`.
Il publish non la tocca, quindi una modifica ai glifi fa ancora scattare un DIFF prima che finisca online.

## Rischi e punti aperti

**Il submodule `fonts/wb` punta a GitLab via SSH.**
Chi clona `github.com/s-e-a-m/sean` pubblicamente non ottiene i glifi WB, quindi non può compilare né il catalogo né metà dei test.
Non blocca un `make publish` lanciato dalla macchina di Giuseppe, ma rende sean non riproducibile da terzi proprio mentre lo si pubblica.
Il trasferimento a `s-e-a-m` è già in `TODO.md`: la sua priorità sale.

**I file generati stanno in un repo che si scrive a mano.**
Mitigato dal commento di avviso, non risolto.

**Il repository del sito non segue lo standard del workspace.**
`s-e-a-m.github.io` non ha `CLAUDE.md`, `TODO.md` né `logs/`, e sta per diventare il punto di arrivo di tre pipeline.
In questo lavoro si aggiunge al suo `README.md` la mappa delle collection, dei blocchi marcati in `navigation.yml` e la regola sui file generati.
Portarlo allo standard pieno è una decisione a parte, fuori da questa spec.

**La lingua del vocabolario di sean** resta aperta, per una sessione dedicata.

## Documentazione da aggiornare

- **`README.md`** dei tre repo: una sezione *Documentazione online* con l'URL della propria reference e il comando `make publish`.
- **`CLAUDE.md`** dei tre repo: come si pubblica, e la regola che GitHub Pages di repo resta spento.
- **`TODO.md`**: in `sean`, la lingua del vocabolario e il submodule `fonts/wb`; in `seam-ltm`, il registro dei plugin.
- **`logs/YYYY-MM-DD-processo.md`** in ciascun repo toccato, a fase conclusa.
- **`README.md`** del sito: mappa delle collection, blocchi marcati, file generati.
