import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

Stream<List<Map<String, dynamic>>> getZonas() {
  return db.collection('zonas').snapshots().map((queryZonas) {
    List<Map<String, dynamic>> zonas = [];

    for (var documento in queryZonas.docs) {
      final Map<String, dynamic> data = documento.data();
      data['uid'] = documento.id;
      zonas.add(data);
    }

    return zonas;
  });
}

Future<void> updateConfiguracionZona(
  String uid, {
  int? nuevoAforo,
  List<String>? nuevasClasesPeligrosas,
  List<String>? nuevasClasesIgnorar,
}) async {
  Map<String, dynamic> datosAActualizar = {};

  if (nuevoAforo != null) {
    datosAActualizar['config.aforo_max'] = nuevoAforo;
  }

  if (nuevasClasesPeligrosas != null) {
    datosAActualizar['config.clases.peligrosas'] = nuevasClasesPeligrosas;
  }

  if (nuevasClasesIgnorar != null) {
    datosAActualizar['config.clases.ignorar'] = nuevasClasesIgnorar;
  }

  if (datosAActualizar.isNotEmpty) {
    await db.collection('espacios').doc(uid).update(datosAActualizar);
  }
}

Future<void> deleteZona(String uid) async {
  await db.collection('zonas').doc(uid).delete();
}
