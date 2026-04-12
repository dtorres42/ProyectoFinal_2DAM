import 'package:flutter/material.dart';
import 'create_user_screen.dart';
import 'delete_user_screen.dart';
import 'update_user_screen.dart';
import 'list_users_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de administración"),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AdminButton(
                text: "Consultar usuarios",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListUsersScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),

              _AdminButton(
                text: "Crear usuario",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateUserScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),

              _AdminButton(
                text: "Editar usuario",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UpdateUserScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),

              _AdminButton(
                text: "Eliminar usuario",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeleteUserScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _AdminButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(color: Colors.white)),
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
