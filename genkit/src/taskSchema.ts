import {z} from "zod";

/**
 * Schema Zod per la validazione di un incarico AI.
 */
export const TaskSchema = z.object({
  nome: z.string(),
  cognome: z.string(),
  indirizzo: z.string(),
  telefono: z.string(),
  email: z.string().email().or(z.literal("")),
  codicefiscale: z.string(),
  partitaIva: z.string(),
  tipoCliente: z.enum(["Amministratore", "Azienda", "Privato", "Referente"]),
  tipo: z.enum(["Intervento", "Contratto"]),
  cartello: z.boolean(),
  categoria: z.enum(["Disinfestazione", "Spurgo", "Video"]),
  problematica: z.string(),
  programmato: z.boolean(),
  operatore: z.string(),
  data: z.string(), // In formato YYYY-MM-DD
  oraInizio: z.string(), // In formato HH:MM
  oraFine: z.string(), // In formato HH:MM
  allDay: z.boolean(),
  isRepeated: z.boolean(),
  dataInizioRipetizione: z.string(), // YYYY-MM-DD
  dataFineRipetizione: z.string(), // YYYY-MM-DD
  giornoMeseRipetizione: z.number(),
  ogniQuantiMesiRipetizione: z.number(),
});

/**
 * Normalizza i dati grezzi estratti dall'AI per aderire allo schema TaskSchema.
 *
 * @param {Record<string, unknown>} raw Oggetto contenente dati da normalizzare.
 * @return {Record<string, unknown>} Oggetto normalizzato.
 */
export function normalizzaDatiGreppiati(
  raw: Record<string, unknown>
): Record<string, unknown> {
  return {
    nome: normalizeString(raw.nome),
    cognome: normalizeString(raw.cognome),
    indirizzo: normalizeString(raw.indirizzo),
    telefono: normalizeString(raw.telefono),
    email: normalizeString(raw.email).toLowerCase(),
    codicefiscale: normalizeString(raw.codicefiscale).toUpperCase(),
    partitaIva: normalizeString(raw.partitaIva),
    tipoCliente: normalizzaEnum(raw.tipoCliente, [
      "Amministratore", "Azienda", "Privato", "Referente",
    ]),
    tipo: normalizzaEnum(raw.tipo, ["Intervento", "Contratto"]),
    cartello: normalizzaBoolean(raw.cartello),
    categoria: normalizzaEnum(raw.categoria, [
      "Disinfestazione", "Spurgo", "Video",
    ]),
    problematica: normalizeString(raw.problematica),
    programmato: normalizzaBoolean(raw.programmato),
    operatore: normalizeString(raw.operatore),
    data: normalizeString(raw.data),
    oraInizio: normalizeString(raw.oraInizio),
    oraFine: normalizeString(raw.oraFine),
    allDay: normalizzaBoolean(raw.allDay),
    isRepeated: normalizzaBoolean(raw.isRepeated),
    dataInizioRipetizione: normalizeString(raw.dataInizioRipetizione),
    dataFineRipetizione: normalizeString(raw.dataFineRipetizione),
    giornoMeseRipetizione: normalizeNumber(raw.giornoMeseRipetizione),
    ogniQuantiMesiRipetizione: normalizeNumber(raw.ogniQuantiMesiRipetizione),
  };
}

/**
 * Normalizza una stringa a un valore predefinito tra quelli validi.
 *
 * @param {unknown} val - Valore da normalizzare.
 * @param {string[]} validi - Elenco dei valori validi.
 * @return {string} Valore normalizzato.
 */
function normalizzaEnum(val: unknown, validi: string[]): string {
  if (typeof val !== "string") return validi[0];
  const trovato = validi.find(
    (v) => v.toLowerCase() === val.trim().toLowerCase()
  );
  return trovato ?? validi[0];
}

/**
 * Converte un valore generico in booleano.
 *
 * @param {unknown} val - Valore da convertire.
 * @return {boolean} Booleano risultante.
 */
function normalizzaBoolean(val: unknown): boolean {
  if (typeof val === "boolean") return val;
  if (typeof val === "string") {
    const s = val.trim().toLowerCase();
    return s === "true" || s === "sì" || s === "si" || s === "1";
  }
  if (typeof val === "number") return val === 1;
  return false;
}

/**
 * Converte un valore generico in stringa.
 *
 * @param {unknown} val - Valore da convertire.
 * @return {string} Stringa risultante.
 */
function normalizeString(val: unknown): string {
  return typeof val === "string" ? val.trim() : "";
}

/**
 * Converte un valore generico in numero intero, oppure 0 se non valido.
 *
 * @param {unknown} val - Valore da convertire.
 * @return {number} Numero risultante.
 */
function normalizeNumber(val: unknown): number {
  const n = Number(val);
  return isNaN(n) ? 0 : Math.floor(n);
}
