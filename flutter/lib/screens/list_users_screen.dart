import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_final_2dam/screens/update_user_screen.dart';

class ListUsersScreen extends StatelessWidget {
  const ListUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Listar usuarios"),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No hay usuarios"));
            }

            final users = snapshot.data!.docs;

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final data = user.data() as Map<String, dynamic>;

                final role = (data['rol'] ?? 'user').toString();

                if (role == 'admin') {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(data['nombre'] ?? 'Sin nombre'),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UpdateUserScreen(uid: user.id),
                          ),
                        );
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
