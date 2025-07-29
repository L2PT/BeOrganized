const admin = require('firebase-admin');
const fs = require('fs-extra');
const path = require('path');

admin.initializeApp({
  credential: admin.credential.cert(require('./firebase-service-account.json')),
  storageBucket: 'com-l2pt-venturiautospurghi.appspot.com'
});

const bucket = admin.storage().bucket();
const LOCAL_SESSION_PATH = './session-data';

async function downloadSession() {
  try {
    await fs.ensureDir(LOCAL_SESSION_PATH);
    const [files] = await bucket.getFiles({ prefix: 'session-data/' });
    for (const file of files) {
      const dest = path.join(LOCAL_SESSION_PATH, path.basename(file.name));
      await file.download({ destination: dest });
      console.log(`✅ Scaricato ${file.name}`);
    }
  } catch (err) {
    console.error('❌ Errore download sessione:', err);
  }
}

async function uploadSession() {
  try {
    const files = await fs.readdir(LOCAL_SESSION_PATH);
    for (const file of files) {
      await bucket.upload(path.join(LOCAL_SESSION_PATH, file), {
        destination: `session-data/${file}`
      });
      console.log(`✅ Caricato ${file}`);
    }
  } catch (err) {
    console.error('❌ Errore upload sessione:', err);
  }
}

module.exports = { downloadSession, uploadSession };
