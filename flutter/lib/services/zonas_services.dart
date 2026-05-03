import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore zonasDb = FirebaseFirestore.instance;

Stream<List<Map<String, dynamic>>> getZonasActivas() {
  return zonasDb
      .collection('zonas')
      .where('activo', isEqualTo: true)
      .snapshots()
      .map(
        (snap) => snap.docs.map((doc) {
          final data = doc.data();
          data['uid'] = doc.id;
          return data;
        }).toList(),
      );
}

Stream<List<Map<String, dynamic>>> getTodasLasZonas() {
  return zonasDb.collection('zonas').snapshots().map(
        (snap) => snap.docs.map((doc) {
          final data = doc.data();
          data['uid'] = doc.id;
          return data;
        }).toList(),
      );
}

Stream<Map<String, dynamic>?> getZonaPorId(String zonaId) {
  return zonasDb.collection('zonas').doc(zonaId).snapshots().map((doc) {
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['uid'] = doc.id;
    return data;
  });
}

Future<void> crearZona({
  required String nombre,
  required String descripcion,
  required String urlConexion,
  required Map<String, int> objetivos,
}) async {
  await zonasDb.collection('zonas').add({
    'nombre': nombre,
    'descripcion': descripcion,
    'url_conexion': urlConexion,
    'activo': true,
    'objetivos': objetivos,
    'estado': {
      'objetos': {},
      'online': false,
      'actualizado_el': FieldValue.serverTimestamp(),
    },
  });
}

Future<void> actualizarZona(
  String zonaId, {
  String? nombre,
  String? descripcion,
  String? urlConexion,
  Map<String, int>? objetivos,
  bool? activo,
}) async {
  final campos = <String, dynamic>{};
  if (nombre != null) campos['nombre'] = nombre;
  if (descripcion != null) campos['descripcion'] = descripcion;
  if (urlConexion != null) campos['url_conexion'] = urlConexion;
  if (activo != null) campos['activo'] = activo;

  if (campos.isNotEmpty) {
    await zonasDb.collection('zonas').doc(zonaId).update(campos);
  }

  if (objetivos != null) {
    await zonasDb.collection('zonas').doc(zonaId).set(
      {'objetivos': objetivos},
      SetOptions(merge: true),
    );
  }
}

Future<void> desactivarZona(String zonaId) async {
  await zonasDb.collection('zonas').doc(zonaId).update({'activo': false});
}

Future<void> deleteZona(String zonaId) async {
  final alertas = await FirebaseFirestore.instance
      .collection('alertas')
      .where('zona_id', isEqualTo: zonaId)
      .get();
  for (final doc in alertas.docs) {
    await doc.reference.delete();
  }

  final historial = await FirebaseFirestore.instance
      .collection('historial')
      .where('zona_id', isEqualTo: zonaId)
      .get();
  for (final doc in historial.docs) {
    await doc.reference.delete();
  }
  await zonasDb.collection('zonas').doc(zonaId).delete();
}
