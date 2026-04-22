import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore alertasDb = FirebaseFirestore.instance;

Stream<List<Map<String, dynamic>>> getAlertasActivas() {
  return alertasDb
      .collection('alertas')
      .where('estado', whereIn: ['activa', 'en_proceso'])
      .snapshots()
      .map((snap) {
        final alertas = snap.docs.map((doc) {
          final data = doc.data();
          data['uid'] = doc.id;
          return data;
        }).toList();

        alertas.sort((a, b) {
          final tA = a['timestamp'] as Timestamp? ?? Timestamp.now();
          final tB = b['timestamp'] as Timestamp? ?? Timestamp.now();
          return tB.compareTo(tA);
        });

        return alertas;
      });
}

Stream<List<Map<String, dynamic>>> getAlertasPorZona(
  String zonaId, {
  int limite = 20,
}) {
  return alertasDb
      .collection('alertas')
      .where('zona_id', isEqualTo: zonaId)
      .orderBy('timestamp', descending: true)
      .limit(limite)
      .snapshots()
      .map(
        (snap) => snap.docs.map((doc) {
          final data = doc.data();
          data['uid'] = doc.id;
          return data;
        }).toList(),
      );
}

Stream<List<Map<String, dynamic>>> getHistorialAlertas({int limite = 50}) {
  return alertasDb
      .collection('alertas')
      .orderBy('timestamp', descending: true)
      .limit(limite)
      .snapshots()
      .map(
        (snap) => snap.docs.map((doc) {
          final data = doc.data();
          data['uid'] = doc.id;
          return data;
        }).toList(),
      );
}

Future<void> atenderAlerta(
  String uid,
  String nombreVigilante,
  String userUid,
) async {
  await alertasDb.collection('alertas').doc(uid).update({
    'estado': 'en_proceso',
    'atendida_por': nombreVigilante,
  });
  await alertasDb.collection('usuarios').doc(userUid).update({
    'alertas_gestionadas': FieldValue.increment(1),
  });
}

Future<void> resolverAlerta(String uid) async {
  await alertasDb.collection('alertas').doc(uid).update({'estado': 'resuelta'});
}

Future<void> deleteAlerta(String uid) async {
  await alertasDb.collection('alertas').doc(uid).delete();
}

Stream<int> getAlertasHoyPorZona(String zonaId) {
  final hoy = DateTime.now();
  final fecha =
      "${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}";
  return FirebaseFirestore.instance
      .collection('alertas')
      .where('zona_id', isEqualTo: zonaId)
      .where('fecha', isEqualTo: fecha)
      .snapshots()
      .map((snap) => snap.docs.length);
}
