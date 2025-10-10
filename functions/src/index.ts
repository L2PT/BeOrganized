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

interface NotificationData {
  tokens: string[];
  title: string;
  description: string;
  style: string;
  type: string;
  eventId: string;
}

export const sendNotifications = onCall<NotificationData>(async (request) => {
  // Verifica autenticazione (opzionale ma consigliato)
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Utente non autenticato');
  }

  const { tokens, title, description, style, type, eventId } = request.data;

  // Validazione dei dati
  if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
    throw new HttpsError('invalid-argument', 'I token sono obbligatori');
  }

  const messages = tokens.map((token: string) => ({
    token: token,
    notification: {
      title: title,
      body: description,
    },
    data: {
      id: eventId,
      style: style,
      type: type,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      notification: {
        sound: 'default'
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default'
        }
      }
    }
  }));

  try {
    const response = await admin.messaging().sendEach(messages);

    // Log dei risultati
    console.log(`Inviate ${response.successCount} notifiche su ${tokens.length}`);

    if (response.failureCount > 0) {
      const failedTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
          console.error(`Errore per token ${tokens[idx]}:`, resp.error);
        }
      });

      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
        failedTokens: failedTokens
      };
    }

    return {
      success: true,
      successCount: response.successCount,
      failureCount: 0
    };

  } catch (error) {
    console.error('Errore invio notifiche:', error);

    if (error instanceof Error) {
      throw new HttpsError('internal', error.message);
    }

    throw new HttpsError('internal', 'Errore sconosciuto durante l\'invio delle notifiche');
  }
});