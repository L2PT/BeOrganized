const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode  = require('qrcode');
import fs from 'fs';
import path from 'path';

// ----------------------------
// Configurazione GCS
// ----------------------------
const LOCAL_PATH = '/tmp/session';  // unica cartella scrivibile in Cloud Run

// Crea la cartella locale se non esiste
if (!fs.existsSync(LOCAL_PATH)) fs.mkdirSync(LOCAL_PATH, { recursive: true });

let qrCodeData = '';
// Configurazione Client WhatsApp
const client = new Client({
    authStrategy: new LocalAuth({
        clientId: 'whatsapp-client',
        dataPath: LOCAL_PATH
    }),
    puppeteer: {
        headless: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-zygote',
            '--disable-gpu',
            '--disable-web-security',
            '--disable-features=VizDisplayCompositor',
            '--single-process',
            '--disable-extensions',
            '--disable-background-timer-throttling',
            '--disable-backgrounding-occluded-windows',
            '--disable-renderer-backgrounding'
        ],
        timeout: 60000
    }
});

// Event Listeners
client.on('qr', async (qr) => {
    console.log('🔍 QR Code ricevuto:');
    qrCodeData = qr;

    // Invia via webhook se configurato
    if (process.env.QR_WEBHOOK_URL) {
        sendQRCodeViaWebhook(qr);
    }
});

client.on('ready', async () => {
    console.log('✅ WhatsApp Client è pronto!');
});

client.on('authenticated', () => {
    console.log('🔐 Autenticazione completata');
});

client.on('auth_failure', (msg) => {
    console.error('❌ Autenticazione fallita:', msg);
});

client.on('disconnected', (reason) => {
    console.log('🔌 Disconnesso:', reason);

    setTimeout(() => {
        console.log('🔄 Tentativo di riconnessione...');
        client.initialize();
    }, 5000);
});

client.on('remote_session_saved', () => {
    console.log('💾 Sessione salvata su Firebase');
});

client.on('error', (error) => {
    console.error('🚨 Errore WhatsApp Client:', error);

    if (error.message.includes('Execution context was destroyed')) {
        console.log('🔄 Contesto distrutto, reinizializzo...');
        setTimeout(() => {
            client.initialize();
        }, 3000);
    }
});

client.on('message', msg => {
  try {
    console.log('📥 Messaggio ricevuto:');
    console.log('Da:', msg._data.notifyName || msg.from);
    console.log('Numero:', msg.from);
    console.log('Testo:', msg.body);
  } catch (err) {
    console.error('Errore gestione messaggio:', err);
  }
});



// Funzione helper per inviare QR via webhook
async function sendQRCodeViaWebhook(qr) {
    try {
        const response = await fetch(process.env.QR_WEBHOOK_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                qr: qr,
                timestamp: new Date().toISOString(),
                instance: 'whatsapp-session'
            })
        });
        console.log('📤 QR inviato via webhook');
    } catch (error) {
        console.error('❌ Errore invio QR webhook:', error);
    }
}

// Funzione per inviare messaggio con retry
async function sendMessageWithRetry(number, message, maxRetries = 3) {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            // Normalizza numero
            const chatId = number.includes('@c.us') ? number : `${number}@c.us`;

            // Invia messaggio
            const sentMessage = await client.sendMessage(chatId, message);

            console.log(`✅ Messaggio inviato al tentativo ${attempt}`);

            // Restituisci un oggetto con info
            return {
                status: 'ok',
                messageId: sentMessage.id._serialized,
                sentTo: chatId,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            console.error(`❌ Tentativo ${attempt} fallito:`, error.message);

            // Caso particolare: contesto distrutto
            if (error.message.includes('Execution context was destroyed')) {
                console.log('🔄 Contesto distrutto, attendo prima del retry...');
                await new Promise(resolve => setTimeout(resolve, 2000 * attempt));
                continue;
            }

            // Riprova se non è l’ultimo tentativo
            if (attempt < maxRetries) {
                await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
                continue;
            }

            // Se tutti i tentativi falliscono
            throw error;
        }
    }
}


// Express App per API
const express = require('express');
const app = express();
app.use(express.json());

// Endpoint per inviare messaggi
app.post('/send-message', async (req, res) => {
    try {
        const { number, message } = req.body;

        if (!number || !message) {
            return res.status(400).json({
                error: 'chatId e message sono richiesti'
            });
        }

        const result = await sendMessageWithRetry(number, message);

        res.json({
            success: true,
            res: result
        });
    } catch (error) {
        console.error('Errore invio messaggio:', error);
        res.status(500).json({
            error: 'Errore invio messaggio',
            details: error.message
        });
    }
});

// Endpoint per ottenere il QR code corrente
app.get('/qr', async (req, res) => {
    try {
      qrCodeDataImg = await qrcode.toDataURL(qrCodeData);
      if (qrCodeDataImg) {
        return res.send(`
          <div style="text-align:center;font-family:Arial;">
            <h2>Scansiona il QR</h2>
            <img src="${qrCodeDataImg}" style="border:1px solid #ccc;padding:10px"/>
          </div>`);
      }
      res.send('⏳ Generazione QR… <script>setTimeout(()=>location.reload(),3000)</script>');
    } catch (error) {
        console.error('Errore recupero QR:', error);
        res.status(500).json({
            error: 'Errore recupero QR code',
            details: error.message
        });
    }
});

app.get('/qr-code', async (req, res) => {
    try {
        if (!qrCodeData) {
            return res.send('⏳ QR non ancora generato, riprova...');
        }

        res.json({
            qrCodeData // stringa del QR grezza
        });
    } catch (error) {
        console.error('Errore recupero QR:', error);
        res.status(500).json({
            error: 'Errore recupero QR code',
            details: error.message
        });
    }
});


// Avvio applicazione
async function start() {
    try {
        console.log('🚀 Avvio WhatsApp Bot su Cloud Run con Firebase...');

        // Inizializza WhatsApp client
        await client.initialize();

        // Avvia server Express
        const port = process.env.PORT || 8080;
        app.listen(port, () => {
            console.log(`🌐 Server avviato sulla porta ${port}`);
            console.log(`📱 QR Code disponibile su: http://localhost:${port}/qr`);
        });

    } catch (error) {
        console.error('❌ Errore durante avvio:', error);
        process.exit(1);
    }
}

// Avvia l'applicazione
start();