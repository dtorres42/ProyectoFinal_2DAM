import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/screens/cameras_screen.dart';
import 'package:proyecto_final_2dam/screens/home_screen.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRol();
  }

  Future<void> _loadRol() async {
    final rol = await getRolUsuarioActual();
    print(' El usuario actual tiene el ROL: $rol');
    setState(() {
      _isAdmin = rol == 'admin';
      _loading = false;
    });
  }

  List<Widget> get _screens => const [
    HomeScreen(),
    CamerasScreen(),
    _PlaceholderScreen(
      icon: Icons.notifications_outlined,
      title: 'Alertas',
      subtitle: 'Esta pantalla se puede conectar después con el historial.',
    ),
    _PlaceholderScreen(
      icon: Icons.person_outline,
      title: 'Perfil',
      subtitle: 'Aquí puedes añadir la información del usuario más adelante.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildNav(),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              shape: const CircleBorder(),
              elevation: 4,
              tooltip: 'Añadir nueva cámara',
              onPressed: () => Navigator.pushNamed(context, 'nueva_zona'),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNav() {
    return BottomAppBar(
      color: AppTheme.surface,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              outline: Icons.home_outlined,
              solid: Icons.home,
              label: 'Inicio',
              index: 0,
            ),
            _navItem(
              outline: Icons.videocam_outlined,
              solid: Icons.videocam,
              label: 'Cámaras',
              index: 1,
            ),

            if (_isAdmin) const SizedBox(width: 48),

            _navItemAlertas(),

            _navItem(
              outline: Icons.person_outline,
              solid: Icons.person,
              label: 'Perfil',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData outline,
    required IconData solid,
    required String label,
    required int index,
  }) {
    final selected = _selectedIndex == index;
    final color = selected ? AppTheme.primaryLight : AppTheme.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedIndex = index),
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? solid : outline,
              color: color,
              size: selected ? 28 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),