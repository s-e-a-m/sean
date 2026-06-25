## Convenzioni comuni

> Blocco identico in tutti i repo del workspace `gs`.
> Sorgente di verità: `gs/CLAUDE.md`.
> Se modifichi questa sezione, propagala a tutti i repo.

Questo repository segue lo standard di documentazione del dottorato.
Quattro materiali sono **sempre presenti** e coerenti con lo stato reale del progetto:

- **README.md** — spiega il progetto a un esterno: cos'è, com'è organizzato, perché.
  Ogni sessione di lavoro verifica che il README rispecchi lo stato reale.
  Se è divergente, lo si aggiorna prima di chiudere.
- **CLAUDE.md** — questo file.
  La prima sezione *Convenzioni comuni* è identica in tutti i repo; il resto è la guida specifica a questo progetto.
- **TODO.md** — i task che emergono durante la lavorazione, come checklist (`- [ ]` / `- [x]`).
  Con gli eventuali issue su GitLab, è ciò che rende l'avanzamento organizzato.
- **logs/** — una cartella con un file per intervento, `YYYY-MM-DD-processo.md`.
  Ogni processo, elaborazione o intervento significativo lascia un log datato.
  Così resta tracciata la storia degli interventi.

**Una frase per riga.**
Tutta la documentazione si scrive una frase per riga: a capo dopo il punto, riga vuota per il paragrafo.
Serve a rendere puliti i diff di git.

**Lingua.**
Non c'è una lingua imposta: ogni repo usa la propria lingua di origine e destinazione.
Questo blocco di convenzioni comuni resta in italiano perché identico ovunque; il resto della documentazione segue la lingua del repo.

**Attribuzione.**
Ogni log e ogni modifica dichiara *chi* è intervenuto (Giuseppe, Alice, o l'agente).
Chi propone o lavora su un repo non suo rispetta queste regole e segnala il proprio contributo.

## Guida specifica — sean

### Cos'è

`sean` (Sustained ElectroAcoustic Notation) è una libreria TikZ per scrivere diagrammi a blocchi della musica elettroacustica come partiture.
È un sistema notazionale autonomo che interopera con `circuitikz` ma non ne dipende.
Nasce dalla trascrizione dei simboli di Walter Branchi, *Tecnologie della musica elettronica* (1976), estesi all'uso contemporaneo.
Il README è la descrizione canonica del progetto: leggilo prima di lavorare qui.

### Idea centrale: frase vs font

La **frase** è il diagramma astratto: identità di segno (`gmic`, `amp`, `lspk`…) collegate per nome, indipendenti dallo stile.
Il **font** è lo stile di un autore/tradizione (WB, GS, …) che disegna quei segni: si cambia font e la catena resta, cambia il segno.
L'**ereditarietà** lascia che un font dichiari un genitore (`gs` con `parent=wb`) e ridisegni solo ciò che vuole, il resto ricade sul genitore.
È la distinzione carattere vs glifo: il vocabolario astratto è l'encoding condiviso, ogni font fornisce i glifi.

### Struttura

Il motore vive in `lib/` (`substrate.tex` definisce il contratto: vocabolario, ancore, macchina font, fallback/override, provenienza, errori).
`tikzlibrarysean.code.tex` è il loader caricato da `\usetikzlibrary{sean}`.
I font stanno in `fonts/`: `wb/` è un submodule (`wb-tdme-simboli`, branch `font-wb-puro`) che contiene *solo glifi*; `gs/` è il font della mano di Giuseppe Silvi.
`docs/` ha il documento-catalogo e le spec; `test/` i test (compilazione + marker `SEAN-OK`) con i riferimenti di regressione visiva in `test/ref/`.

### Build & test

- `make test` — compila i test e verifica i marker `SEAN-OK`.
- `make render` — produce PDF/PNG dei test visivi e del catalogo.
- `make regress` — confronta i render coi riferimenti in `test/ref/` (segnala DIFF).
- `make ref` — aggiorna i riferimenti, solo se le modifiche visive sono volute.

La compilazione è **XeLaTeX** (richiede il font Datalegreya e `circuitikz` per il ponte).
Esempio: `TEXINPUTS=<root_di_sean>: xelatex documento.tex`.

### Note operative

Il submodule `fonts/wb` punta ancora a `git@gitlab.com:giuseppesilvi/wb-tdme-simboli.git`: senza chiave SSH GitLab un clone pubblico non lo scarica (trasferimento a `s-e-a-m` tracciato in `TODO.md`).
Il repo è pubblicato su `github.com/s-e-a-m/sean` (default `main`); gli issue vanno aperti lì.
Le ancore seguono la rotazione del `pic`; le rotazioni e le frecce di direzione sono a carico di chi scrive il diagramma, mai automatiche.
Prima di toccare i glifi WB controlla le voci "da verificare con la fonte cartacea" elencate nel README.
