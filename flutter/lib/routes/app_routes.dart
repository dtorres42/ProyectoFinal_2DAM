import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/screens/screens.dart';

class AppRoutes {
  static const initialRoute = 'login';

  static Map<String, Widget Function(BuildContext)> routes = {
    'login': (BuildContext context) => const LoginScreen(),
    'home': (BuildContext context) =>
        HomeScreen(email: ModalRoute.of(context)!.settings.arguments as String),
    'create_user': (BuildContext context) => const CreateUserScreen(),
    'delete_user': (BuildContext context) => const DeleteUserScreen(),
    'update_user': (BuildContext context) => const UpdateUserScreen(),
    'admin': (BuildContext context) => const AdminScreen(),
    'list_user': (BuildContext context) => const ListUsersScreen(),
  };
}
