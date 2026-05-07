import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/screens/screens.dart';

class AppRoutes {
  static const initialRoute = 'splash';

  static Map<String, Widget Function(BuildContext)> routes = {
    'splash': (context) => const SplashScreen(),
    'login': (BuildContext context) => const LoginScreen(),
    'nav': (context) => const NavigationScreen(),
    'user_manage': (BuildContext context) => const UserManagement(),
    'zona_detalle': (context) => ZonaDetalleScreen(
          zona: ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>,
        ),
    'edit_zona': (context) => EditScreen(
          zona: ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?,
        ),
  };
}
