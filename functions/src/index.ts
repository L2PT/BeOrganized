import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

// Inizializza Firebase Admin SDK
admin.initializeApp();

/**
 * Funzione HTTPS callable per ottenere dati da una URL esterna.
 * @param {object} data - Deve contenere `url`.
 * @returns {object} - Risposta della richiesta GET o errore.
 */
exports.getDataFromUrl = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  const url = data.url;

  if (!url) {
    throw new functions.https.HttpsError("invalid-argument", "URL non fornita.");
  }

  try {
    const response = await axios.get(url);
    return response.data;
  } catch (error) {
    throw new functions.https.HttpsError("unknown", error.message || "Errore durante la richiesta HTTP.");
  }
});

/**
 * Funzione HTTPS callable per cancellare un utente dato uid.
 * Richiede che l'utente chiamante sia un admin autenticato.
 * @param {object} data - Deve contenere `uid`.
 * @returns {object} - Oggetto con `success: true` oppure errore.
 */
exports.deleteUserByUid = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  console.log("Richiesta ricevuta per deleteUserByUid", {
    requesterUid: context.auth?.uid,
    isAuthenticated: !!context.auth,
    data,
  });

  // Controllo autorizzazione
  if (!context.auth) {
    console.warn("Accesso negato: utente non autenticato.");
    throw new functions.https.HttpsError("permission-denied", "Accesso non autorizzato.");
  }

  const uid = data.uid;
  if (!uid) {
    console.error("ID utente non fornito.");
    throw new functions.https.HttpsError("invalid-argument", "Id non fornito.");
  }

  try {
    console.log(`Tentativo di eliminazione utente con uid: ${uid}`);
    await admin.auth().deleteUser(uid);
    console.log(`Utente con uid ${uid} eliminato con successo.`);
    return { success: true };
  } catch (error) {
    console.error("Errore durante l'eliminazione dell'utente:", error);
    throw new functions.https.HttpsError("unknown", error.message || "Errore durante l'eliminazione dell'utente.");
  }
});



