import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Rellena todos los campos")));
      return;
    }

    if (!email.contains("@") || !email.contains(".")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Introduce un correo válido")),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La contraseña debe tener al menos 8 caracteres"),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(email: email)),
    );
  }

  void goHome() {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Introduce un correo primero")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(email: email)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Iniciar Sesión"),
        centerTitle: true,
        backgroundColor: mainBlue,
      ),

      bottomNavigationBar: Container(
        height: 70,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomIcon(icon: Icons.home, onTap: goHome),
            const _BottomIcon(icon: Icons.camera_alt),
            const _BottomIcon(icon: Icons.smartphone),
            const _BottomIcon(icon: Icons.notifications),
            const _BottomIcon(icon: Icons.history),
          ],
        ),
      ),

      body: Container(
        color: Colors.grey[300],
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                "Correo:",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),

              const SizedBox(height: 5),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "Escribe tu correo...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Contraseña:",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),

              const SizedBox(height: 5),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Escribe tu contraseña...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "¿Has olvidado tu contraseña?",
                  style: TextStyle(fontSize: 13),
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: mainBlue),
                    onPressed: login,
                    child: const Text(
                      "Acceder",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
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
  final VoidCallback? onTap;

  const _BottomIcon({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
