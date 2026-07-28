import {z} from "zod";

/**
 * Schema Zod per la validazione di un incarico AI.
 */
export const TaskSchema = z.object({
  nome: z.string().catch(""),
  cognome: z.string().catch(""),
  indirizzo: z.string().catch(""),
  telefono: z.array(z.string()).catch([]),
  email: z.string().catch(""),
  codicefiscale: z.string().catch(""),
  partitaIva: z.string().catch(""),
  tipoCliente: z.enum(["Amministratore", "Azienda", "Privato", "Referente"]).catch("Privato"),
  referenti: z.array(z.object({
    nome: z.string().catch(""),
    telefono: z.string().catch(""),
  })).catch([]),
  tipo: z.enum(["Intervento", "Contratto"]).catch("Intervento"),
  cartello: z.boolean().catch(false),
  categoria: z.enum(["Disinfestazione", "Spurgo", "Video"]).catch("Spurgo"),
  problematica: z.string().catch(""),
  programmato: z.boolean().catch(false),
  operatore: z.string().catch(""),
  data: z.string().catch(""),
  oraInizio: z.string().catch(""),
  oraFine: z.string().catch(""),
  allDay: z.boolean().catch(false),
  isRepeated: z.boolean().catch(false),
  dataInizioRipetizione: z.string().catch(""),
  dataFineRipetizione: z.string().catch(""),
  giornoMeseRipetizione: z.number().catch(0),
  ogniQuantiMesiRipetizione: z.number().catch(0),
  note: z.string().catch(""),
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
    telefono: normalizeArray(raw.telefono), // Gestisce array di stringhe
    email: normalizeString(raw.email).toLowerCase(),
    codicefiscale: normalizeString(raw.codicefiscale).toUpperCase(),
    partitaIva: normalizeString(raw.partitaIva),
    tipoCliente: normalizzaEnum(raw.tipoCliente, [
      "Amministratore", "Azienda", "Privato", "Referente",
    ]),
    referenti: normalizeReferenti(raw.referenti), // Gestisce array di referenti
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
    note: normalizeString(raw.note), // Campo note aggiunto
  };
}

/**
 * Funzione helper per normalizzare array di stringhe.
 *
 * @param {unknown} value Oggetto contenente dati da normalizzare.
 * @return {string[]} Oggetto normalizzato.
 */
function normalizeArray(value: unknown): string[] {
  if (value === null || value === undefined) return [];
  if (Array.isArray(value)) {
    return value
      .map((item) => normalizeString(item))
      .filter((item) => item !== "");
  }
  return [];
}

/**
 * Funzione helper per normalizzare array di referenti.
 *
 * @param {unknown} value Oggetto contenente dati da normalizzare.
 * @return {{nome: string, telefono: string}[]} Array normalizzato di referenti.
 */
function normalizeReferenti(value: unknown): Array<{ nome: string; telefono: string }> {
  if (!Array.isArray(value)) return [];

  return value
    .filter((item): item is Record<string, unknown> =>
      typeof item === "object" && item !== null
    )
    .map((referente) => ({
      nome: normalizeString(referente.nome),
      telefono: normalizeString(referente.telefono),
    }))
    .filter((r): r is { nome: string; telefono: string } =>
      r.nome !== "" && r.telefono !== ""
    );
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
  if (typeof val !== "string") return "";
  const trimmed = val.trim();
  console.log("normalizzazione stringa:",
    val);
  console.log("Placeholder:", isPlaceholder(trimmed) );
  return isPlaceholder(trimmed) ? "" : trimmed;
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

/**
 * Verifica che è un placeholder
 *
 * @param {string} val - Valore da verificare.
 * @return {boolean} Booleano risultante.
 */
function isPlaceholder(val: string): boolean {
  const placeholders = [
    "NOME", "COGNOME", "INDIRIZZO", "EMAIL", "CODICE_FISCALE", "PARTITA_IVA",
    "TELEFONO1", "TELEFONO2", "TIPO_CLIENTE", "NOME_REF", "COGNOME_REF", "TIPO",
    "TELEFONO_REF", "CATEGORIA", "DESCRIZIONE_PROBLEMA", "GIORNO", "SI/NO",
    "NOTE_AGGIUNTIVE", "YYYY-MM-DD", "HH:MM", "NUMERO_MESI", "NOME_OPERATORE",
  ];
  const normalized = val.trim().toUpperCase();
  return placeholders.includes(normalized);
}
