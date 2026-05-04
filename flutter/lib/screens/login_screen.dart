import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/widgets/widgets.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _viewPass = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _passFocusNode = FocusNode();
  final _email = TextEditingController();
  final _password = TextEditingController();

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      FocusScope.of(context).unfocus();

      final user = await iniciarSesion(
        _email.text.trim(),
        _password.text.trim(),
      );

      if (mounted) {
        if (user != null) {
          final datos = await getUsuarioPorId(user.uid);
          final esPrimerLogin = datos?['primer_login'] as bool? ?? false;

          if (esPrimerLogin && mounted) {
            await _mostrarCambioContrasena(user.uid);
          }

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, 'nav', (_) => false);
          }
        } else {
          setState(() => _isLoading = false);
          _mostrarAlerta('Acceso denegado', 'Email o contraseña incorrectos.');
        }
      }
    }
  }

  Future<void> _mostrarCambioContrasena(String uid) async {
    final newPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool guardando = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Cambia tu contraseña',
            style: TextStyle(color: AppTheme.textPrim, fontSize: 16),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Es tu primer acceso. Por seguridad establece una contraseña personal.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  labelText: 'Nueva contraseña',
                  controller: newPassCtrl,
                  obscureText: true,
                  validator: (v) => (v ?? '').trim().length < 6
                      ? 'Mínimo 6 caracteres.'
                      : null,
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(context),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: guardando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialog(() => guardando = true);

                      await cambiarPassword(newPassCtrl.text.trim());
                      await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(uid)
                          .update({'primer_login': false});

                      if (context.mounted) Navigator.pop(context);
                    },
              child: Text(guardando ? 'Guardando...' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAlerta(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          titulo,
          style: const TextStyle(color: AppTheme.textPrim, fontSize: 16),
        ),
        content: Text(
          mensaje,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: AppTheme.primary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'VigilAI',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrim,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sistema de seguridad inteligente',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                CustomTextFormField(
                  controller: _email,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _passFocusNode.requestFocus(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Introduce tu email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _password,
                  focusNode: _passFocusNode,
                  labelText: 'Contraseña',
                  obscureText: _viewPass,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _viewPass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _viewPass = !_viewPass),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Introduce tu contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      if (_email.text.trim().isEmpty) {
                        _mostrarAlerta('Aviso', 'Introduce tu email primero.');
                        return;
                      }
                      final ok = await resetPassword(_email.text.trim());
                      if (mounted) {
                        ok
                            ? _mostrarAlerta(
                                'Enviado',
                                'Revisa tu bandeja de entrada.',
                              )
                            : _mostrarAlerta(
                                'Error',
                                'No se pudo enviar el correo.',
                              );
                      }
                    },
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                const SizedBox(height: 28),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _handleLogin,
                        child: const Text('Iniciar sesión'),
                      ),
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    'Acceso protegido · Cifrado AES-256',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passFocusNode.dispose();
    super.dispose();
  }
}
