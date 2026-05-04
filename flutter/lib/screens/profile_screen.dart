import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

// Imports específicos para la versión 3.0.1
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _usuario;
  bool _loading = true;
  bool _huellaActiva = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarEstadoHuella();
  }

  Future<void> _cargarEstadoHuella() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _huellaActiva = prefs.getBool('huella_enabled') ?? false;
      });
    }
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

  Future<void> _toggleHuella() async {
    if (!_huellaActiva) {
      try {
        // Verificamos si el móvil puede usar biometría
        final bool canCheck = await auth.canCheckBiometrics;
        final bool isSupported = await auth.isDeviceSupported();

        if (!canCheck && !isSupported) {
          _mostrarError('Este dispositivo no admite biometría');
          return;
        }

        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Escanea tu huella para activar el acceso',
        );

        if (didAuthenticate) {
          final prefs = await SharedPreferences.getInstance();
          final uidActual =
              obtenerUidActual(); // Obtenemos el UID de Admin o el que esté logueado

          if (uidActual != null) {
            await prefs.setBool('huella_enabled', true);
            await prefs.setString('huella_user_uid',
                uidActual); // <--- GUARDAMOS EL UID ESPECÍFICO

            setState(() => _huellaActiva = true);
            _mostrarExito('¡Huella vinculada a esta cuenta!');
          }
        }
      } catch (e) {
        _mostrarError('Error al autenticar: $e');
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('huella_enabled', false);
      setState(() => _huellaActiva = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.red,
    ));
  }

  void _mostrarExito(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green,
    ));
  }

  Future<void> _editarNombre() async {
    if (_usuario == null) return;
    final controller = TextEditingController(text: _usuario!['nombre']);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Editar nombre',
            style: TextStyle(color: AppTheme.textPrim)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await actualizarNombre(_usuario!['uid'], controller.text.trim());
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
    await cerrarSesion();
    if (mounted)
      Navigator.pushNamedAndRemoveUntil(context, 'login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final nombre = _usuario!['nombre'] ?? '';
    final email = _usuario!['email'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Perfil', style: TextStyle(color: AppTheme.textPrim)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildAvatar(nombre),
            const SizedBox(height: 16),
            Text(nombre,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrim)),
            Text(email, style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 30),

            // Switch de Huella
            _buildAccionHuella(),

            const SizedBox(height: 12),
            _buildAccion(
                icon: Icons.edit_outlined,
                label: 'Editar nombre',
                onTap: _editarNombre),
            const SizedBox(height: 12),
            _buildAccion(
                icon: Icons.logout_rounded,
                label: 'Cerrar sesión',
                color: AppTheme.red,
                onTap: _logout),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionHuella() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.fingerprint_rounded, color: AppTheme.primary),
          const SizedBox(width: 12),
          const Expanded(
              child: Text('Habilitar huella digital',
                  style: TextStyle(color: AppTheme.textPrim))),
          Switch(
            value: _huellaActiva,
            onChanged: (val) => _toggleHuella(),
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String nombre) {
    return CircleAvatar(
      radius: 45,
      backgroundColor: AppTheme.primary,
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: const TextStyle(
            fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAccion(
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color color = AppTheme.primary}) {
    return ListTile(
      onTap: onTap,
      tileColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      leading: Icon(icon, color: color),
      title: Text(label,
          style: TextStyle(
              color: color == AppTheme.red ? AppTheme.red : AppTheme.textPrim)),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
    );
  }
}
