import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteUserScreen extends StatelessWidget {
  const DeleteUserScreen({super.key});

  Future<void> deleteUser(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Usuario eliminado")));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar usuario")),
      );
    }
  }

  Future<void> confirmDelete(BuildContext context, String uid) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmar eliminación"),
          content: const Text(
            "¿Seguro que quieres borrar este usuario? Esta acción no se puede deshacer.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Borrar", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await deleteUser(context, uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Eliminar usuario"),
        centerTitle: true,
        backgroundColor: mainBlue,
      ),

      body: Container(
        color: Colors.grey[300],
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data!.docs;

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final data = user.data() as Map<String, dynamic>;

                final role = data['rol'] ?? 'user';

                if (role == 'admin') {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(data['nombre'] ?? ''),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        confirmDelete(context, user.id);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
