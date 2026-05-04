import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';
import 'package:proyecto_final_2dam/widgets/widgets.dart';

class EditScreen extends StatefulWidget {
  final Map<String, dynamic>? zona;
  const EditScreen({super.key, this.zona});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _urlController;
  late TextEditingController _searchController;
  late Map<String, dynamic> _objetivosEditables;
  late bool _activo;
  bool _guardando = false;
  bool _borrando = false;
  List<String> _sugerencias = [];

  @override
  void initState() {
    super.initState();
    final datos = widget.zona ?? {};
    _nameController =
        TextEditingController(text: datos['nombre']?.toString() ?? '');
    _descController =
        TextEditingController(text: datos['descripcion']?.toString() ?? '');
    _urlController =
        TextEditingController(text: datos['url_conexion']?.toString() ?? '');
    _searchController = TextEditingController();
    _objetivosEditables = Map<String, dynamic>.from(datos['objetivos'] ?? {});
    _activo = datos['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(List<String> todasLasClases, String query) {
    if (query.trim().isEmpty) {
      setState(() => _sugerencias = []);
      return;
    }
    setState(() {
      _sugerencias = todasLasClases
          .where((c) => c.contains(query.toLowerCase().trim()))
          .where((c) => !_objetivosEditables.containsKey(c))
          .take(5)
          .toList();
    });
  }

  void _addObject(String nombre, List<String> todasLasClases) {
    if (nombre.trim().isEmpty) return;

    if (!todasLasClases.contains(nombre)) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$nombre" no es un objeto reconocido por el modelo'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_objetivosEditables.containsKey(nombre)) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$nombre" ya está en la lista'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _objetivosEditables[nombre] = 0;
      _searchController.clear();
      _sugerencias = [];
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final zonaId = widget.zona?['uid'] as String?;
    final Map<String, int> objetivos = _objetivosEditables.map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );

    try {
      if (zonaId != null) {
        await actualizarZona(
          zonaId,
          nombre: _nameController.text.trim(),
          descripcion: _descController.text.trim(),
          urlConexion: _urlController.text.trim(),
          objetivos: objetivos,
          activo: _activo,
        );
      } else {
        await crearZona(
          nombre: _nameController.text.trim(),
          descripcion: _descController.text.trim(),
          urlConexion: _urlController.text.trim(),
          objetivos: objetivos,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al guardar. Inténtalo de nuevo.')),
        );
      }
    }
  }

  Future<void> _confirmarBorrar() async {
    final zonaId = widget.zona?['uid'] as String?;
    final nombre = widget.zona?['nombre'] as String? ?? '';
    if (zonaId == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar zona?',
            style: TextStyle(color: AppTheme.textPrim, fontSize: 16)),
        content: Text(
          'Se eliminará "$nombre" junto con todas sus alertas e historial. Esta acción no se puede deshacer.',
          style: const TextStyle(
              color: AppTheme.textMuted, fontSize: 13, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _borrando = true);

    try {
      await deleteZona(zonaId);
      if (mounted) {
        Navigator.popUntil(context, (route) => route.settings.name == 'nav');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zona eliminada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _borrando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al eliminar. Inténtalo de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esNueva = widget.zona == null;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppTheme.textPrim, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          esNueva ? 'Nueva zona' : 'Editar zona',
          style: const TextStyle(
            color: AppTheme.textPrim,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<List<String>>(
        stream: getClasesYolo(),
        builder: (context, snap) {
          final todasLasClases = snap.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DATOS BÁSICOS',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      )),
                  const SizedBox(height: 12),
                  CustomTextFormField(
                    labelText: 'Nombre',
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Introduce el nombre.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  CustomTextFormField(
                    labelText: 'Descripción',
                    controller: _descController,
                    validator: (_) => null,
                  ),
                  const SizedBox(height: 14),
                  CustomTextFormField(
                    labelText: 'URL de conexión',
                    hintText: 'rtsp://usuario:password@ip:554/stream1',
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Introduce la URL de conexión.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  if (!esNueva) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Zona activa',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrim,
                                    )),
                                const SizedBox(height: 4),
                                Text(
                                  _activo
                                      ? 'El servidor procesa esta zona'
                                      : 'El servidor ignora esta zona',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _activo,
                            onChanged: (v) => setState(() => _activo = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ] else
                    const SizedBox(height: 28),
                  const Text('OBJETIVOS — LÍMITES',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      )),
                  const SizedBox(height: 12),
                  if (_objetivosEditables.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'No hay objetivos configurados',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    )
                  else
                    ..._objetivosEditables.entries.map((entry) =>
                        _buildObjectSelector(
                            entry.key, (entry.value as num).toInt())),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (q) => _onSearchChanged(todasLasClases, q),
                    onSubmitted: (_) => _addObject(
                        _searchController.text.trim(), todasLasClases),
                    style:
                        const TextStyle(color: AppTheme.textPrim, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Añadir objeto',
                      hintText: 'Ej: person, scissors...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            color: AppTheme.primary),
                        onPressed: () => _addObject(
                            _searchController.text.trim(), todasLasClases),
                      ),
                    ),
                  ),
                  if (_sugerencias.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: _sugerencias
                            .map((clase) => InkWell(
                                  onTap: () =>
                                      _addObject(clase, todasLasClases),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.add_rounded,
                                            color: AppTheme.primary, size: 16),
                                        const SizedBox(width: 10),
                                        Text(clase,
                                            style: const TextStyle(
                                              color: AppTheme.textPrim,
                                              fontSize: 13,
                                            )),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      child:
                          Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                    ),
                  ),
                  if (!esNueva) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.red.withValues(alpha: .12),
                          foregroundColor: AppTheme.red,
                          elevation: 0,
                          side: const BorderSide(color: AppTheme.red),
                        ),
                        onPressed: _borrando ? null : _confirmarBorrar,
                        child:
                            Text(_borrando ? 'Eliminando...' : 'Eliminar zona'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildObjectSelector(String key, int val) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            const Border(left: BorderSide(color: AppTheme.primary, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(key,
                    style: const TextStyle(
                      color: AppTheme.textPrim,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                const Text('Límite de detección',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _objetivosEditables.remove(key)),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.red, size: 18),
          ),
          const SizedBox(width: 12),
          _counterButton(Icons.remove_rounded, () {
            if ((_objetivosEditables[key] as int) > 0) {
              setState(() => _objetivosEditables[key]--);
            }
          }),
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            alignment: Alignment.center,
            child: Text('$val',
                style: const TextStyle(
                  color: AppTheme.textPrim,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
          ),
          _counterButton(Icons.add_rounded, () {
            setState(() => _objetivosEditables[key]++);
          }),
        ],
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.textPrim, size: 18),
      ),
    );
  }
}
