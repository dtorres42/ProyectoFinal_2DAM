import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateUserScreen extends StatefulWidget {
  final String uid;

  const UpdateUserScreen({super.key, required this.uid});

  @override
  State<UpdateUserScreen> createState() => _UpdateUserScreenState();
}

class _UpdateUserScreenState extends State<UpdateUserScreen> {
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      nameController.text = data['nombre'] ?? '';
      lastNameController.text = data['apellidos'] ?? '';
      emailController.text = data['email'] ?? '';
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> updateUser() async {
    setState(() => saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uid)
          .update({
            'nombre': nameController.text.trim(),
            'apellidos': lastNameController.text.trim(),
            'email': emailController.text.trim(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Usuario actualizado")));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar usuario")),
      );
    }

    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Colors.blue;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar usuario"),
        centerTitle: true,
        backgroundColor: mainBlue,
      ),

      body: Container(
        color: Colors.grey[300],
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: "Apellidos"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saving ? null : updateUser,
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Guardar cambios"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
