const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getAuth } = require("firebase-admin/auth");

setGlobalOptions({ region: "europe-southwest1" });
initializeApp();

exports.onNuevaAlerta = onDocumentCreated("alertas/{alertaId}", async (event) => {
  const alerta = event.data?.data();
  if (!alerta) return;

  if (alerta.notificada) return;
  await event.data.ref.update({ notificada: true });

  const objeto     = alerta.objeto     ?? "Objeto desconocido";
  const zonaNombre = alerta.zona_nombre ?? "Zona desconocida";
  const cantidad   = alerta.cantidad   ?? 0;
  const limite     = alerta.limite     ?? 0;

  const db       = getFirestore();
  const usuarios = await db.collection("usuarios").get();

  const tokens = [];
  usuarios.forEach((doc) => {
    const token = doc.data().fcm_token;
    if (token) tokens.push(token);
  });

  if (tokens.length === 0) return;

  const mensaje = {
    notification: {
      title: `Alerta - ${zonaNombre}`,
      body: `${cantidad} ${objeto} detectados${limite === 0 ? " (prohibido)" : ` · limite ${limite}`}`,
    },
    data: {
      alertaId: event.params.alertaId,
      zona: zonaNombre,
      tipo: "alerta",
    },
    android: {
      notification: {
        channelId: "alertas_channel",
        priority: "high",
        sound: "default",
      },
    },
    tokens,
  };

  const respuesta = await getMessaging().sendEachForMulticast(mensaje);
  console.log(`Notificaciones enviadas: ${respuesta.successCount} ok, ${respuesta.failureCount} fallidas`);

  const tokensBorrar = [];
  respuesta.responses.forEach((resp, i) => {
    if (!resp.success) {
      const codigo = resp.error?.code;
      if (
        codigo === "messaging/invalid-registration-token" ||
        codigo === "messaging/registration-token-not-registered"
      ) {
        tokensBorrar.push(tokens[i]);
      }
    }
  });

  if (tokensBorrar.length > 0) {
    const batch = db.batch();
    usuarios.forEach((doc) => {
      if (tokensBorrar.includes(doc.data().fcm_token)) {
        batch.update(doc.ref, { fcm_token: null });
      }
    });
    await batch.commit();
    console.log(`Tokens invalidos limpiados: ${tokensBorrar.length}`);
  }
});

exports.crearUsuario = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "No autenticado");

  const db  = getFirestore();
  const doc = await db.collection("usuarios").doc(request.auth.uid).get();
  if (doc.data()?.rol !== "admin") {
    throw new HttpsError("permission-denied", "Solo los administradores pueden crear usuarios");
  }

  const { nombre, email, password, rol } = request.data;

  const userRecord = await getAuth().createUser({ email, password });

  await db.collection("usuarios").doc(userRecord.uid).set({
    uid:          userRecord.uid,
    nombre,
    email,
    rol:          rol ?? "usuario",
    primer_login: true,
  });

  return { uid: userRecord.uid };
});

exports.borrarUsuario = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "No autenticado");

  const db  = getFirestore();
  const doc = await db.collection("usuarios").doc(request.auth.uid).get();
  if (doc.data()?.rol !== "admin") {
    throw new HttpsError("permission-denied", "Solo los administradores pueden borrar usuarios");
  }

  const { uid } = request.data;

  if (uid === request.auth.uid) {
    throw new HttpsError("invalid-argument", "No puedes eliminarte a ti mismo");
  }

  await getAuth().deleteUser(uid);
  await db.collection("usuarios").doc(uid).delete();

  return { ok: true };
});