import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth auth = FirebaseAuth.instance;

Future<User?> registrarUsuario(String email, String password) async {
  try {
    UserCredential credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  } on FirebaseAuthException catch (e) {
    print("Error en registro: ${e.code}");
    return null;
  } catch (e) {
    print(e);
    return null;
  }
}

Future<User?> iniciarSesion(String email, String password) async {
  try {
    UserCredential credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  } on FirebaseAuthException catch (e) {
    print("Error en login: ${e.code}");
    return null;
  }
}

Future<void> cerrarSesion() async {
  await auth.signOut();
}

String? obtenerUidActual() {
  return auth.currentUser?.uid;
}

Future<bool> resetPassword(String email) async {
  try {
    await auth.sendPasswordResetEmail(email: email.trim());
    return true;
  } on FirebaseAuthException catch (e) {
    print("Error reset: ${e.code}");
    return false;
  }
}

Future<void> cambiarPassword(String nuevaPassword) async {
  await FirebaseAuth.instance.currentUser?.updatePassword(nuevaPassword);
}
