const express = require('express');
const qrcode = require('qrcode');
const { Client, LocalAuth } = require('whatsapp-web.js');
const { downloadSession, uploadSession } = require('./sessionManager');

const app = express();
let qrCodeData = '';

(async () => {
  await downloadSession();

  const client = new Client({
    authStrategy: new LocalAuth({ dataPath: './session-data' }),
    puppeteer: {
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    }
  });

  client.on('qr', async qr => {
    qrCodeData = await qrcode.toDataURL(qr);
    console.log('⚠️ Scansiona il QR code!');
  });

  client.on('ready', () => {
    console.log('✅ Client pronto!');
  });

  client.on('authenticated', async () => {
    console.log('🔐 Autenticato!');
    await uploadSession();
  });

  client.on('disconnected', async () => {
    console.log('⚠️ Disconnesso!');
    await uploadSession();
  });

  client.initialize();
})();

app.get('/qr', (req, res) => {
  if (qrCodeData) {
    res.send(`<img src="${qrCodeData}" />`);
  } else {
    res.send('QR code non ancora generato. Riprova...');
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`🌐 Server avviato su http://localhost:${PORT}`));
