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
      title: `Nueva alerta — ${zonaNombre}`,
      body: `${cantidad} ${objeto} detectados${limite === 0 ? " (prohibido)" : ` · límite ${limite}`}`,
    },
    android: {
      notification: {
        channelId: "alertas_channel",
        priority: "high",
      },
    },
    tokens: tokens,
  };

  const respuesta = await getMessaging().sendEachForMulticast(mensaje);
  console.log(`Notificaciones enviadas: ${respuesta.successCount} ok, ${respuesta.failureCount} fallidas`);
});