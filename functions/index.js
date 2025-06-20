/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentCreated} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onRequest, onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require('firebase-admin');
admin.initializeApp();

// ========== Funcție trimitere notificare push pentru apeluri =========
exports.sendCallNotification = onCall(async (data, context) => {
  const { targetUid, title, body, callId, isVideoCall } = data;
  if (!targetUid || !title || !body) {
    throw new Error('Parametrii lipsesc');
  }

  // Găsește tokenul FCM pentru utilizatorul țintă
  const userDoc = await admin.firestore().collection('users').doc(targetUid).get();
  const token = userDoc.data()?.fcmToken;
  if (!token) {
    throw new Error('Utilizatorul nu are token FCM.');
  }

  // Payload notificare
  const payload = {
    notification: {
      title: title,
      body: body,
      click_action: "FLUTTER_NOTIFICATION_CLICK"
    },
    data: {
      callId: callId || "",
      isVideoCall: String(isVideoCall ?? true),
    }
  };

  // Trimite notificarea!
  try {
    await admin.messaging().sendToDevice(token, payload);
    return { success: true };
  } catch (e) {
    throw new Error('Notificarea nu a putut fi trimisă: ' + e.message);
  }
});

// ========== Funcție trimitere notificare push pentru urgență (PACIENT -> MEDIC) =========
exports.sendEmergencyAlarm = onRequest(async (req, res) => {
  try {
    const medicId = req.body.medicId || req.query.medicId;
    const pacientNume = req.body.pacientNume || req.query.pacientNume;
    const pacientId = req.body.pacientId || req.query.pacientId;

    if (!medicId || !pacientNume) {
      logger.error("Lipsesc datele! medicId:", medicId, "pacientNume:", pacientNume);
      res.status(400).send("Lipsesc datele!");
      return;
    }

    const medicDoc = await admin.firestore().collection('users').doc(medicId).get();
    const fcmToken = medicDoc.data()?.fcmToken;

    logger.log("MedicId:", medicId, "Token:", fcmToken);

    if (!fcmToken) {
      logger.error("Medicul nu are token.");
      res.status(404).send("Medicul nu are token.");
      return;
    }

    const payload = {
      notification: {
        title: "Urgență pacient!",
        body: `Pacientul ${pacientNume} are o urgență!`,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      },
      data: {
        pacientId: pacientId || '',
      }
    };

    logger.log("Payload:", JSON.stringify(payload));

    try {
      await admin.messaging().sendToDevice(fcmToken, payload);
      logger.log("Notificare FCM trimisă cu succes");
      res.send("Trimis!");
    } catch (e) {
      logger.error("Eroare la sendToDevice:", e && e.stack ? e.stack : e);
      res.status(500).send("Eroare la sendToDevice: " + (e && e.stack ? e.stack : e));
    }

  } catch (e) {
    logger.error("Eroare generală în sendEmergencyAlarm:", e && e.stack ? e.stack : e);
    res.status(500).send("Eroare: " + (e && e.stack ? e.stack : e));
  }
});

// ========== Funcție trimitere notificare push când se adaugă o alarmă (MEDIC sau PACIENT) =========
exports.sendAlarmNotification = onDocumentCreated("users/{userId}/alarms/{alarmId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const alarm = snap.data();
  const userId = event.params.userId;

  // Ia tokenul FCM din Firestore pentru userId
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  const fcmToken = userDoc.data()?.fcmToken;

  if (!fcmToken) {
    logger.log('Nu există token FCM pentru userId:', userId);
    return;
  }

  const payload = {
    notification: {
      title: 'Alarmă medicament',
      body: alarm.title || 'Este timpul să iei medicamentul!',
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    data: {
      screen: 'alarms',
      alarmId: event.params.alarmId,
    }
  };

  try {
    await admin.messaging().sendToDevice(fcmToken, payload);
    logger.log('Notificare trimisă la', fcmToken);
  } catch (e) {
    logger.error('Eroare la trimitere notificare:', e);
  }
});
