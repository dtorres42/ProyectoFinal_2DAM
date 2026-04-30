import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore histoDb = FirebaseFirestore.instance;

Stream<List<Map<String, dynamic>>> getHistorialZona(
  String zonaId, {
  int limite = 48,
}) {
  return histoDb
      .collection('historial')
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
