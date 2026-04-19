import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidosController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': nombreController.text.trim(),
        'apellidos': apellidosController.text.trim(),
        'email': emailController.text.trim(),
        'rol': 'user',
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario creado correctamente")),
      );

      nombreController.clear();
      apellidosController.clear();
      emailController.clear();
      passwordController.clear();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Error creando usuario")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error inesperado")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear usuario"),
        centerTitle: true,
        backgroundColor: mainBlue,
      ),

      bottomNavigationBar: Container(
        height: 70,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _BottomIcon(icon: Icons.home),
            _BottomIcon(icon: Icons.camera_alt),
            _BottomIcon(icon: Icons.smartphone),
            _BottomIcon(icon: Icons.notifications),
            _BottomIcon(icon: Icons.history),
          ],
        ),
      ),

      body: Container(
        color: Colors.grey[300],
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (value) =>
                    value!.isEmpty ? "Introduce nombre" : null,
              ),

              TextFormField(
                controller: apellidosController,
                decoration: const InputDecoration(labelText: "Apellidos"),
                validator: (value) =>
                    value!.isEmpty ? "Introduce apellidos" : null,
              ),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Correo"),
                validator: (value) =>
                    value!.contains("@") ? null : "Correo inválido",
              ),

              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Contraseña"),
                validator: (value) =>
                    value!.length < 6 ? "Mínimo 6 caracteres" : null,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: isLoading ? null : createUser,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Crear usuario"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final IconData icon;

  const _BottomIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, color: Colors.white),
    );
  }
}
