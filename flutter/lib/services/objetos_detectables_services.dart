import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore _db = FirebaseFirestore.instance;

Stream<List<String>> getClasesYolo() {
  return _db.collection('objetos_detectables').snapshots().map((snap) {
    final clases = snap.docs
        .map((doc) => doc.data()['nombre'] as String? ?? '')
        .where((nombre) => nombre.isNotEmpty)
        .toList();
    clases.sort();
    return clases;
  });
}
