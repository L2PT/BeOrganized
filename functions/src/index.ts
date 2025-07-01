import { onCall, CallableRequest, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

interface GetDataRequest {
  url: string;
}

export const getDataFromUrl = onCall(async (request: CallableRequest<GetDataRequest>) => {
  const url = request.data.url;

  if (!url) {
    throw new HttpsError("invalid-argument", "URL non fornita.");
  }

  try {
    const response = await axios.get(url);
    return response.data;
  } catch (error: unknown) {
    if (error instanceof Error) {
      throw new HttpsError("internal", error.message || "Errore durante la richiesta HTTP.");
    }
    throw new HttpsError("internal", "Errore durante la richiesta HTTP.");
  }
});

interface DeleteUserRequest {
  uid: string;
}

export const deleteUserByUid = onCall(
  async (request: CallableRequest<DeleteUserRequest>) => {
    const { uid } = request.data;

    console.log("Richiesta ricevuta per deleteUserByUid", {
      requesterUid: request.auth?.uid,
      isAuthenticated: !!request.auth,
      data: request.data,
    });

    // Controllo autorizzazione
    if (!request.auth) {
      console.warn("Accesso negato: utente non autenticato.");
      throw new HttpsError("permission-denied", "Accesso non autorizzato.");
    }

    if (!uid) {
      console.error("ID utente non fornito.");
      throw new HttpsError("invalid-argument", "Id non fornito.");
    }

    try {
      console.log(`Tentativo di eliminazione utente con uid: ${uid}`);
      await admin.auth().deleteUser(uid);
      console.log(`Utente con uid ${uid} eliminato con successo.`);
      return { success: true };
    } catch (error: unknown) {
      console.error("Errore durante l'eliminazione dell'utente:", error);
      if (error instanceof Error) {
        throw new HttpsError("internal", error.message || "Errore durante l'eliminazione dell'utente.");
      }
      throw new HttpsError("internal", "Errore durante l'eliminazione dell'utente.");
    }
  }
);

