import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _usuario;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final uid = obtenerUidActual();
    if (uid == null) return;
    final data = await getUsuarioPorId(uid);
    if (mounted) {
      setState(() {
        _usuario = data;
        _loading = false;
      });
    }
  }

  Future<void> _editarNombre() async {
    final controller = TextEditingController(text: _usuario!['nombre']);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar nombre',
            style: TextStyle(color: AppTheme.textPrim, fontSize: 16)),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final nuevoNombre = controller.text.trim();
              if (nuevoNombre.isEmpty) return;
              await actualizarNombre(_usuario!['uid'], nuevoNombre);
              if (mounted) Navigator.pop(context);
              _cargarUsuario();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión',
            style: TextStyle(color: AppTheme.textPrim, fontSize: 16)),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await cerrarSesion();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, 'login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_usuario == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Text('No se pudo cargar el usuario',
              style: TextStyle(color: AppTheme.textMuted)),
        ),
      );
    }

    final nombre = _usuario!['nombre'] as String? ?? '';
    final email = _usuario!['email'] as String? ?? '';
    final rol = _usuario!['rol'] as String? ?? 'usuario';
    final alertasGestionadas = _usuario!['alertas_gestionadas'] as int? ?? 0;
    final esAdmin = rol == 'admin';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: AppTheme.textPrim,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrim,
              ),
            ),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                esAdmin ? 'Administrador' : 'Usuario',
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    '$alertasGestionadas',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrim,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Alertas gestionadas',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildAccion(
              icon: Icons.edit_outlined,
              label: 'Editar nombre',
              onTap: _editarNombre,
            ),
            const SizedBox(height: 10),
            if (esAdmin) ...[
              _buildAccion(
                icon: Icons.person_add_outlined,
                label: 'Crear usuario',
                onTap: () => Navigator.pushNamed(context, 'user_manage'),
              ),
              const SizedBox(height: 10),
            ],
            _buildAccion(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesión',
              color: AppTheme.red,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccion({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppTheme.primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      color == AppTheme.red ? AppTheme.red : AppTheme.textPrim,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
