import 'package:flutter/material.dart';

class DeleteUserScreen extends StatelessWidget {
  const DeleteUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Eliminar usuario"),
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
        child: const Center(
          child: Text(
            "Implementar lógica",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
