import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

Stream<List<Map<String, dynamic>>> getAlertasActivas() {
  return db
      .collection('alertas')
      .where('estado', whereIn: ['activa', 'en_proceso'])
      .snapshots()
      .map((queryAlertas) {
        List<Map<String, dynamic>> alertas = [];

        for (var documento in queryAlertas.docs) {
          final Map<String, dynamic> data = documento.data();
          data['uid'] = documento.id;
          alertas.add(data);
        }

        alertas.sort((a, b) {
          Timestamp timeA = a['timestamp'] ?? Timestamp.now();
          Timestamp timeB = b['timestamp'] ?? Timestamp.now();
          return timeB.compareTo(timeA);
        });

        return alertas;
      });
}

Future<void> atenderAlerta(String uid, String nombreVigilante) async {
  await db.collection('alertas').doc(uid).update({
    'estado': 'en_proceso',
    'atendida_por': nombreVigilante,
  });
}

Future<void> resolverAlertaManual(String uid) async {
  await db.collection('alertas').doc(uid).update({'estado': 'resuelta'});
}

Future<void> deleteAlerta(String uid) async {
  await db.collection('alertas').doc(uid).delete();
}
