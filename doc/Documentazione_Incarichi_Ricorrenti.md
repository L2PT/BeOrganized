# Documentazione Incarichi Ricorrenti

### 1. Concetti di Base ed Engine Dinamico
Per evitare di intasare il database con centinaia di documenti futuri previsti per i prossimi anni, il sistema salva **un solo record nel Database (l'evento Master)**.
Questo Master è caratterizzato da regole precise (`isRepeated = true`, un periodo in mesi `recurrenceIntervalInMonths`, un giorno d’inizio in `recurrenceDayOfMonth`, ecc.) ed un range di date in cui l'abbonamento/serie risulta valida (`recurrenceStart` e `recurrenceEnd`).

Quando un calendario o un cruscotto operatore viene caricato (dalla classe `CloudFirestoreService`), *il sistema genera dinamicamente al volo* in RAM le singole ricorrenze mensili tramite il metodo `generateRecurringEvents`. Tutte queste istanze figlie non hanno un vero e proprio ID di database univoco, ma recano con sé una firma (`recurrenceId`) che permette al sistema di sapere da quale Master provengono.

---

### 2. Modifica Spostamento/Aggiornamento di un incarico

**A) Modifica di una singola occorrenza ("Solo questo")**
Cosa succede a livello di dati:
1. Poiché si tratta di un'istanza fluttuante, al primissimo salvataggio viene creato **un effettivo e nuovo record nel database** distinto e con un proprio ID.
2. A questo record viene applicata un'etichetta speciale: **`isExcepeted = true`** (diventa un'Eccezione/Override della serie).
3. Dal momento in cui subentra questa etichetta, il generatore dinamico interno crea una mappa unica agganciata per Anno e Mese (`"${e.recurrenceId}_${e.start.year}_${e.start.month}"`). Quando il sistema disegna gli eventi futuri, vede che per quel determinato mese c'è stata un'eccezione, **scarta la generazione automatica classica** e usa quella creata ad-hoc nel Database.
*Effetto per l'utente*: Quell'incarico è in tutto e per tutto spaccato dalla serie e ha vita autonoma per data, ora o operatore assegnato. Modificare l'intero pacchetto Master in futuro non sortirà più effetti diretti su questa particolare eccezione.

**B) Modifica di tutto l'abbonamento ("Tutti gli eventi futuri")**
Cosa succede a livello di dati:
1. L'app non crea centinaia di modifiche. Va semplicemente a colpire l'evento base scaricando l'evento **Master** (recuperato grazie a `recurrenceId`).
2. Lo sovrascrive nel database con i nuovi dettagli o la nuova cadenza (nel metodo `_updateEntireSeries`).
*Effetto per l'utente*: Il generatore dinamico da quel momento baserà tutte le prossime proiezioni della serie futura agganciandosi ai nuovi dati/moduli inseriti.

---

### 3. Cancellazione di un incarico

**A) Cancellazione di un solo evento della serie ("Solo questo")**
Cosa succede a livello di dati:
1. Esattamente come nella modifica singola, il sistema distacca e crea una controfigura di questo evento sul database, applicandogli la bandierina **`isExcepeted = true`**.
2. Successivamente questo record fittizio viene etichettato con stato "Cancellato" (`EventStatus.Deleted`) e spostato fisicamente, se previsto, nel registro storico `_collectionStoricoEliminati` come record a parte.
*Effetto per l'utente/operatore*: Quando scorre il nuovo mese, l'engine tenta di generare le copie master, incrocia che per quel mese è stata generata l'eccezione e, siccome ha lo storico Cancellato, non spamma e nasconde del tutto la slot di quell’incarico nel calendario. Dal mese in là si riprende la cadenza prestabilita nel Master.

**B) Chiusura totale dell'abbonamento ("Cancella l'intera serie")**
Cosa succede se un cliente/utente interrope definitivamente le ricorrenze future a partire da un giorno specifico (`deleteAllSeries = true`)?
1. L'app **non cancella l'intero incarico** primario dal Database, per far sì che sui resoconti dei mesi scorsi e le tracce in anagrafica i bilanci o l'elenco abbiano base solida.
2. Il sistema prende il Master principale e modifica il target della data della fine della serie (`end` / `recurrenceEnd`), imponendo una *"scadenza retroattiva"* al giorno del click, letteralmente **un giorno prima** dell'incarico in base al quale hai premuto il cestino (`e.end.subtract(Duration(days: 1))`).
*Effetto per l'utente*: Poiché il periodo di validità globale scade il giorno prima del tuo click, da quel giorno in poi (per gli anni a venire) la query del Calendario non avvierà la stampa di nessuna copia dinamica, ritenendo chiuso il contratto.

---

### 4. Inserimento di un Nuovo Incarico Ricorrente

Quando viene creato un nuovo abbonamento o incarico ripetuto da zero, l'operazione segue questo flusso logico:
1. **Creazione del Master**: L'utente definisce nel form di creazione un intervallo di tempo base (es. dalle 08:00 alle 10:00), una cadenza (es. mensile, ogni 1 mese) e una finestra di validità (`recurrenceStart` e `recurrenceEnd` corrispondente all'inizio e alla fine teorica dell'intero abbonamento).
2. **Flag `isRepeated`**: L'oggetto `Event` viaggia verso il database con il campo `isRepeated = true`.
3. **Salvataggio**: Il `CloudFirestoreService` aggiunge l'evento master alla collezione principale (`_collectionEventi`). Al momento del salvataggio nel DB, una volta ottenuto il nuovo "id" reale del documento da Firebase, questo stesso ID viene di solito utilizzato (o coincide indirettamente) come punto di riferimento parent per agganciarvi l'intera catena di ricorrenze. Non vengono "inserite" le copie future (es. quella tra due o tre mesi): Firebase immagazzina solo il contratto mastro. Le singole presenze si autogenerano al bisogno sulla UI di Mese in Mese.

---

### 5. Esempi di Incarichi in base allo Stato (EventStatus)

Nel ciclo di vita di un incarico (singolo o un'occecorrenza di un ricorrente che è stata visualizzata, modificata o "accettata" dall'operatore diventando quindi un'eccezione `isExcepeted=true`), questo può attraversare i seguenti stati:

*   **Bozza (`-3`)**: *Es. L'amministratore sta redigendo l'incarico per lo spurgo mensile della ditta Rossi, ma non l'ha ancora confermato o inviato sul cloud.*
*   **Nuovo (`0`)**: *Es. Il contratto/incarico è stato appena salvato nel database. L'operatore assegnato non ha ancora ricevuto la notifica o aperto l'app.*
*   **Consegnato (`1`)**: *Es. L'operatore assegnato al giro di spurgo per oggi ha ricevuto la notifica push sul telefono ma non ha ancora aperto i dettagli dell'incarico.*
*   **Visualizzato (`2`)**: *Es. L'operatore ha cliccato sull'evento nel calendario e letto la "Descrizione/Problematica", per valutare se ha le attrezzature giuste, ma non ha ancora premuto 'Accetta'.*
*   **Accettato (`3`)**: *Es. L'operatore si è impegnato a svolgere l'incarico e ha dato la disponibilità. L'organizzatore ora vede che il lavoro del giorno è in capo a lui ("pallino verde"). Nel caso di una ricorrenza, questo specifico evento di questo particolare mese diventa automaticamente un record stand-alone eccezione per poter storicizzare l'accettazione.*
*   **Terminato (`4`)**: *Es. L'operatore ha scaricato l'autobotte e finito lo spurgo. Ha compilato l'incarico dichiarando la conclusione. Viene spostato nello storico completati.*
*   **Rifiutato (`-1`)**: *Es. L'operatore oggi ha un guasto al camion o è in malattia e rifiuta questo evento in programma.*
*   **Eliminato (`-2`)**: *Es. L'incarico è stato disdetto dal cliente. Se faceva parte di una serie, questo record "Eliminato" andrà a nascondere la generazione dell'istanza in questo mese specifico.*
