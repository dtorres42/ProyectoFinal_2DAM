import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

enum _Filtro { todos, admins, usuarios }

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final _searchController = TextEditingController();
  _Filtro _filtro = _Filtro.todos;
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _currentUid = obtenerUidActual();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _aplicarFiltros(List<Map<String, dynamic>> users) {
    final query = _searchController.text.trim().toLowerCase();
    return users.where((u) {
      final rol = u['rol'] as String? ?? 'usuario';
      final nombre = (u['nombre'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();

      final matchFiltro = switch (_filtro) {
        _Filtro.todos => true,
        _Filtro.admins => rol == 'admin',
        _Filtro.usuarios => rol == 'usuario',
      };
      final matchQuery =
          query.isEmpty || nombre.contains(query) || email.contains(query);

      return matchFiltro && matchQuery;
    }).toList();
  }

  bool _puedeEliminar(Map<String, dynamic> user) {
    final rol = user['rol'] as String? ?? 'usuario';
    return user['uid'] != _currentUid && rol != 'admin';
  }

  Future<void> _showCrearUsuario() async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    var esAdmin = false;
    var guardando = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 14,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nuevo usuario',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrim,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: nombreCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Nombre completo'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Introduce el nombre.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) {
                        final e = v?.trim() ?? '';
                        return e.isEmpty || !e.contains('@')
                            ? 'Introduce un email válido.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Contraseña temporal'),
                      validator: (v) => (v ?? '').trim().length < 6
                          ? 'Mínimo 6 caracteres.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Rol administrador',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrim,
                                    )),
                                SizedBox(height: 4),
                                Text('Acceso completo al sistema',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMuted,
                                    )),
                              ],
                            ),
                          ),
                          Switch(
                            value: esAdmin,
                            onChanged: (v) => setModal(() => esAdmin = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: guardando
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModal(() => guardando = true);

                                final user = await registrarUsuario(
                                  emailCtrl.text.trim(),
                                  passwordCtrl.text,
                                );

                                if (user == null) {
                                  if (!context.mounted) return;
                                  setModal(() => guardando = false);
                                  _showSnack('No se pudo crear el usuario.');
                                  return;
                                }

                                await insertUsuario(
                                  user.uid,
                                  nombreCtrl.text.trim(),
                                  emailCtrl.text.trim(),
                                  rol: esAdmin ? 'admin' : 'usuario',
                                );

                                if (!context.mounted) return;
                                Navigator.pop(context);
                                _showSnack('Usuario creado correctamente.');
                              },
                        child: Text(guardando ? 'Creando...' : 'Crear usuario'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEliminar(Map<String, dynamic> user) async {
    if (!_puedeEliminar(user)) {
      _showSnack('No puedes eliminar a este usuario.');
      return;
    }

    var eliminando = false;
    final nombre = user['nombre'] as String? ?? '';
    final email = user['email'] as String? ?? '';

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(nombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrim,
                    )),
                const SizedBox(height: 4),
                Text(email,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textMuted)),
                const SizedBox(height: 16),
                const Text(
                  'Esta acción no se puede deshacer. El usuario perderá el acceso al sistema.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.red.withValues(alpha: .15),
                      foregroundColor: AppTheme.red,
                      elevation: 0,
                      side: const BorderSide(color: AppTheme.red),
                    ),
                    onPressed: eliminando
                        ? null
                        : () async {
                            setDialog(() => eliminando = true);
                            await deleteUsuario(user['uid'] as String);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            _showSnack('Usuario eliminado correctamente.');
                          },
                    child:
                        Text(eliminando ? 'Eliminando...' : 'Eliminar usuario'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: eliminando ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('Usuarios',
            style: TextStyle(
                color: AppTheme.textPrim,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: AppTheme.textPrim, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: _showCrearUsuario,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: getUsuarios(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            final todos = snap.data!;
            final filtrados = _aplicarFiltros(todos);
            final admins = todos.where((u) => u['rol'] == 'admin').length;
            final usuarios = todos.length - admins;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SummaryCard(value: '${todos.length}', label: 'Total'),
                      const SizedBox(width: 10),
                      _SummaryCard(value: '$admins', label: 'Admins'),
                      const SizedBox(width: 10),
                      _SummaryCard(value: '$usuarios', label: 'Usuarios'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children: [
                      _ChipFiltro(
                          label: 'Todos',
                          selected: _filtro == _Filtro.todos,
                          onTap: () => setState(() => _filtro = _Filtro.todos)),
                      _ChipFiltro(
                          label: 'Admins',
                          selected: _filtro == _Filtro.admins,
                          onTap: () =>
                              setState(() => _filtro = _Filtro.admins)),
                      _ChipFiltro(
                          label: 'Usuarios',
                          selected: _filtro == _Filtro.usuarios,
                          onTap: () =>
                              setState(() => _filtro = _Filtro.usuarios)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Buscar usuario...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filtrados.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        'No hay usuarios que coincidan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  else
                    ...filtrados.map((u) => _UserCard(
                          user: u,
                          onDelete:
                              _puedeEliminar(u) ? () => _showEliminar(u) : null,
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  const _SummaryCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrim,
                )),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipFiltro(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onDelete;
  const _UserCard({required this.user, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final nombre = user['nombre'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final rol = user['rol'] as String? ?? 'usuario';
    final esAdmin = rol == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: const TextStyle(
                      color: AppTheme.textPrim,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                const SizedBox(height: 2),
                Text(email,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              esAdmin ? 'Admin' : 'Usuario',
              style: const TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.red, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}
