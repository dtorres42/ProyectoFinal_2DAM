import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

Stream<List<Map<String, dynamic>>> getHistorialCompleto() {
  return db.collection('historial').snapshots().map((queryHistorial) {
    List<Map<String, dynamic>> lista = [];

    for (var documento in queryHistorial.docs) {
      final data = documento.data();
      data['uid'] = documento.id;
      lista.add(data);
    }

    lista.sort((a, b) {
      Timestamp tA = a['timestamp'] ?? Timestamp.now();
      Timestamp tB = b['timestamp'] ?? Timestamp.now();
      return tB.compareTo(tA);
    });

    return lista;
  });
}

Stream<List<Map<String, dynamic>>> getHistorialPorEspacio(String espacioId) {
  return db
      .collection('historial')
      .where('espacio_id', isEqualTo: espacioId)
      .snapshots()
      .map((queryHistorial) {
        List<Map<String, dynamic>> lista = [];

        for (var documento in queryHistorial.docs) {
          final data = documento.data();
          data['uid'] = documento.id;
          lista.add(data);
        }

        lista.sort((a, b) {
          Timestamp tA = a['timestamp'] ?? Timestamp.now();
          Timestamp tB = b['timestamp'] ?? Timestamp.now();
          return tB.compareTo(tA);
        });

        return lista;
      });
}

Future<void> deleteHistorial(String uid) async {
  await db.collection('historial').doc(uid).delete();
}
