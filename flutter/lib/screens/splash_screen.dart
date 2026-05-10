import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decidirRuta();
  }

  Future<void> _decidirRuta() async {
    try {
      final user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 5));

      final recuerdame = await getRecuerdame();

      if (!mounted) return;

      if (user != null && recuerdame) {
        final datos = await getUsuarioPorId(user.uid);
        if (datos == null) {
          await cerrarSesion();
          await guardarRecuerdame(false);
          if (mounted) Navigator.pushReplacementNamed(context, 'login');
          return;
        }
        Navigator.pushReplacementNamed(context, 'nav');
      } else {
        if (user != null && !recuerdame) await cerrarSesion();
        Navigator.pushReplacementNamed(context, 'login');
      }
    } catch (e) {
      if (mounted) Navigator.pushReplacementNamed(context, 'login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );
  }
}
