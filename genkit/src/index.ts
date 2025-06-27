import {genkit} from "genkit";
import {googleAI} from "@genkit-ai/googleai";
import {onCallGenkit} from "firebase-functions/https";
import {defineSecret} from "firebase-functions/params";
import {TaskSchema, normalizzaDatiGreppiati} from "./taskSchema";
import {z} from "zod";
import {enableFirebaseTelemetry} from "@genkit-ai/firebase";

enableFirebaseTelemetry();

const apiKey = defineSecret("GEMINI_API_KEY");

const ai = genkit({
  plugins: [googleAI()],
  model: googleAI.model("gemini-2.0-flash-lite"),
});

const estraiIncarico = ai.defineFlow({
  name: "estraiIncarico",
  inputSchema: z.string(),
  outputSchema: TaskSchema,
}, async (testo: string) => {
  const today = new Date().toISOString().split("T")[0];
  const prompt = `
        Oggi è ${today}.

        Estrai dal seguente testo le informazioni richieste e
        restituisci un JSON con i seguenti campi:
        - nome
        - cognome
        - indirizzo
        - telefono
        - email
        - codicefiscale
        - partitaIva
        - tipoCliente: "Amministratore" o "Azienda" o "Privato" o "Referente"
        - tipo: "Intervento" o "Contratto"
        - cartello
        - categoria: "Disinfestazione" o "Spurgo" o "Video"
        - problematica
        - programmato
        - operatore: nome della persona o squadra assegnata all'incarico
        - data: nel formato "YYYY-MM-DD"
        - oraInizio: nel formato "HH:MM"
        - oraFine: nel formato "HH:MM"
        - allDay: booleano che indica se l'incarico dura l'intera giornata
        - isRepeated: booleano che indica se l'incarico è ripetuto nel tempo
        - dataInizioRipetizione: nel formato "YYYY-MM-DD"
        - dataFineRipetizione: nel formato "YYYY-MM-DD"
        - giornoMeseRipetizione: numero del giorno del mese
         in cui ripetere l'incarico (es. 15)
        - ogniQuantiMesiRipetizione: numero intero che indica ogni quanti
        mesi ripetere l'incarico

        Testo: """${testo}"""
    `;


  const result = await ai.generate(prompt);

  console.log("Contenuto ricevuto dal modello:",
    result.output);

  const normalizzati = normalizzaDatiGreppiati(result.output);

  return TaskSchema.parse(normalizzati);
});

export const estraiIncaricoFlow = onCallGenkit({
  secrets: [apiKey],
}, estraiIncarico);
