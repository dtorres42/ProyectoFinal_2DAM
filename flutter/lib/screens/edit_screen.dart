import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class EditScreen extends StatefulWidget {
  final Map<String, dynamic>? zona;

  const EditScreen({super.key, this.zona});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  // Controladores para los campos de texto
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _urlController;
  late TextEditingController _searchController;

  // Mapa local para gestionar los objetivos y sus límites
  late Map<String, dynamic> _objetivosEditables;

  @override
  void initState() {
    super.initState();

    final datos = widget.zona ?? {};

    // Inicialización de controladores
    _nameController =
        TextEditingController(text: datos['nombre']?.toString() ?? '');
    _descController =
        TextEditingController(text: datos['descripcion']?.toString() ?? '');
    _urlController =
        TextEditingController(text: datos['url']?.toString() ?? '');
    _searchController = TextEditingController();

    // Clonamos los objetivos existentes
    _objetivosEditables = Map<String, dynamic>.from(datos['objetivos'] ?? {});
  }

  @override
  void dispose() {
    // Liberamos todos los controladores al cerrar la pantalla
    _nameController.dispose();
    _descController.dispose();
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Lógica para añadir un nuevo objeto desde el buscador
  void _addNewObject() {
    final String nuevo = _searchController.text.trim().toLowerCase();

    if (nuevo.isNotEmpty) {
      if (_objetivosEditables.containsKey(nuevo)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$nuevo" ya está en la lista')),
        );
        return;
      }

      setState(() {
        _objetivosEditables[nuevo] = 1; // Valor inicial por defecto
        _searchController.clear();
      });

      FocusScope.of(context).unfocus(); // Cierra el teclado
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.zona == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
            child: Text("Error: Datos no encontrados",
                style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Configurar Zona',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('DATOS BÁSICOS'),
            const SizedBox(height: 15),
            _buildTextField(label: 'Nombre', controller: _nameController),
            const SizedBox(height: 15),
            _buildTextField(
                label: 'Descripción',
                controller: _descController,
                hint: 'Ej: Planta principal'),
            const SizedBox(height: 15),
            _buildTextField(
                label: 'URL de conexión',
                controller: _urlController,
                hint: 'rtsp://...'),

            const SizedBox(height: 30),
            _buildSectionTitle('OBJETIVOS — LÍMITES'),
            const SizedBox(height: 15),

            // Lista dinámica de objetivos
            ..._buildDynamicObjects(),

            const SizedBox(height: 10),
            _buildAddObjectSearcher(),

            const SizedBox(height: 40),
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES DE LA INTERFAZ ---

  List<Widget> _buildDynamicObjects() {
    if (_objetivosEditables.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text("No hay objetivos configurados",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        )
      ];
    }

    return _objetivosEditables.entries.map((entry) {
      return _buildObjectSelector(entry.key, (entry.value as num).toInt());
    }).toList();
  }

  Widget _buildObjectSelector(String key, int val) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border:
            const Border(left: BorderSide(color: AppTheme.primary, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(key.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const Text('Límite de detección',
                    style: TextStyle(color: AppTheme.primary, fontSize: 10)),
              ],
            ),
          ),
          _counterButton(Icons.remove, () {
            if (_objetivosEditables[key] > 0) {
              setState(() => _objetivosEditables[key]--);
            }
          }),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: Text('$val',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          _counterButton(Icons.add, () {
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1));
  }

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      String? hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.primary, fontSize: 13),
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAddObjectSearcher() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 55,
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _addNewObject(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Añadir nuevo objeto...',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline,
                color: AppTheme.primary.withOpacity(0.6)),
            onPressed: _addNewObject,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () async {
          // 1. Preparamos el mapa con todos los datos actualizados
          final Map<String, dynamic> datosActualizados = {
            'nombre': _nameController.text,
            'descripcion': _descController.text,
            'url': _urlController.text,
            'objetivos':
                _objetivosEditables, // Aquí van los números que aumentaste
          };

          // 2. Aquí debes llamar a tu función de base de datos
          // Ejemplo si usas un Provider o una función de Firebase:
          // await FirebaseService().updateZona(widget.zona['id'], datosActualizados);

          print("Enviando a la base de datos: $datosActualizados");

          // 3. Volvemos atrás avisando que se guardó
          if (mounted) {
            Navigator.pop(context, datosActualizados);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cambios guardados correctamente')),
            );
          }
        },
        child: const Text('Guardar cambios',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
