import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/screens/screens.dart';

class AppRoutes {
  static const initialRoute = 'login';

  static Map<String, Widget Function(BuildContext)> routes = {
    'login': (BuildContext context) => const LoginScreen(),
    'nav': (context) => const NavigationScreen(),
    'user_manage': (BuildContext context) => const UserManagement(),
    'zona_detalle': (context) => ZonaDetalleScreen(
          zona: ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>,
        ),
    'edit_zona': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    // Si args es nulo, pasamos un mapa vacío para evitar que la app explote
    return EditScreen(zona: (args as Map<String, dynamic>?) ?? {});
    },
  };
}
