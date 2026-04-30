import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/screens/screens.dart';

class AppRoutes {
  static const initialRoute = 'login';

  static Map<String, Widget Function(BuildContext)> routes = {
    'login': (BuildContext context) => const LoginScreen(),
    'nav': (context) => const NavigationScreen(),
    'user_manage': (BuildContext context) => const UserManagement()
  };
}
