# Log di sessione — 2026-06-25 — Allineamento allo standard di documentazione `gs`

## Obiettivo
Allineare il repo `sean` ai quattro materiali standard del workspace `gs` (README, CLAUDE, TODO, logs/).

## Stato trovato
Già presenti e coerenti: `README.md` (ricco, descrizione canonica del progetto), `TODO.md`, cartella `logs/` con tre log datati nel formato `YYYY-MM-DD-<processo>.md`.
Mancava: `CLAUDE.md`.

## Politica applicata
COMPLETARE: il senso del progetto è chiaro dal contenuto reale (README + log), quindi nessun segnaposto.
Creato il solo materiale mancante; gli altri tre erano già allineati e non sono stati toccati.

## Azioni
- Creato `CLAUDE.md`: blocco *Convenzioni comuni* inserito verbatim (byte-identico alla sorgente del workspace) come prima sezione, seguito dalla guida specifica a `sean` (cos'è, idea frase/font, struttura, build & test, note operative).
- I log esistenti in `logs/` non sono stati rinominati né modificati.
- Nessuna modifica a codice, dati, Makefile, `lib/`, `fonts/`, `test/`.

## Chi
**Chi:** Claude (agente), su indicazione di Giuseppe.
