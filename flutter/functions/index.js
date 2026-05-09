const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

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