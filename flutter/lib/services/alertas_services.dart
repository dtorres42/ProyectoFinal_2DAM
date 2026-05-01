import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore alertasDb = FirebaseFirestore.instance;

Stream<List<Map<String, dynamic>>> getAlertasActivas(String userUid) {
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

        final filtradas = alertas.where((a) {
          final estado = a['estado'] as String? ?? '';
          if (estado == 'activa') return true;
          if (estado == 'en_proceso') return a['atendida_por'] == userUid;
          return false;
        }).toList();

        filtradas.sort((a, b) {
          final tA = a['timestamp'] as Timestamp? ?? Timestamp.now();
          final tB = b['timestamp'] as Timestamp? ?? Timestamp.now();
          return tB.compareTo(tA);
        });

        return filtradas;
      });
}

Stream<List<Map<String, dynamic>>> getMisAlertasEnProceso(String nombre) {
  return alertasDb
      .collection('alertas')
      .where('estado', isEqualTo: 'en_proceso')
      .where('atendida_por', isEqualTo: nombre)
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

Stream<List<Map<String, dynamic>>> getAlertasResueltas({int limite = 50}) {
  return alertasDb
      .collection('alertas')
      .where('estado', isEqualTo: 'resuelta')
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

Future<void> atenderAlerta(String uid, String userUid) async {
  await alertasDb.collection('alertas').doc(uid).update({
    'estado': 'en_proceso',
    'atendida_por': userUid,
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
