import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseFirestore userDb = FirebaseFirestore.instance;

Future<Map<String, dynamic>?> getUsuarioPorId(String uid) async {
  final doc = await userDb.collection('usuarios').doc(uid).get();
  if (!doc.exists) return null;

  final data = doc.data() as Map<String, dynamic>;
  return {
    'uid': doc.id,
    'nombre': data['nombre'] ?? 'sin nombre',
    'email': data['email'] ?? 'sin email',
    'rol': data['rol'] ?? 'usuario',
  };
}

Future<String> getRolUsuarioActual() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 'usuario';
  final doc = await userDb.collection('usuarios').doc(user.uid).get();
  return doc.data()?['rol'] as String? ?? 'usuario';
}

Stream<List<Map<String, dynamic>>> getUsuarios() {
  return userDb.collection('usuarios').snapshots().map(
        (snap) => snap.docs.map((doc) {
          final data = doc.data();
          data['uid'] = doc.id;
          return data;
        }).toList(),
      );
}

Future<void> insertUsuario(
  String uid,
  String nombre,
  String email, {
  String rol = 'usuario',
}) async {
  await userDb.collection('usuarios').doc(uid).set({
    'uid': uid,
    'nombre': nombre,
    'email': email,
    'rol': rol,
    'primer_login': true,
  });
}

Future<void> actualizarNombre(String uid, String nuevoNombre) async {
  await userDb.collection('usuarios').doc(uid).update({'nombre': nuevoNombre});
}

Future<void> deleteUsuario(String uid) async {
  await userDb.collection('usuarios').doc(uid).delete();
}
