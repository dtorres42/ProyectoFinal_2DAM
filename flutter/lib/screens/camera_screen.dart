import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class CamerasScreen extends StatelessWidget {
  const CamerasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('zonas').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Error al cargar'));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;

            // Cálculos para los resúmenes
            int totalPersonas = 0;
            int alertasActivas = 0;
            int zonasOnline = 0;

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final estado = data['estado'] ?? {};
              final objetivos = data['objetivos'] ?? {};
              
              int actuales = estado['objetos']?['person'] ?? 0;
              int limite = objetivos['person'] ?? 30;
              bool online = estado['online'] ?? false;

              totalPersonas += actuales;
              if (online) zonasOnline++;
              if (actuales >= limite && online) alertasActivas++;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cámaras', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  Text('$zonasOnline zonas activas', style: const TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                  
                  const SizedBox(height: 25),

                  // Grid de Resumen Superior
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.6,
                    children: [
                      _buildSummaryCard('Total personas', '$totalPersonas', Colors.white),
                      _buildSummaryCard('Alertas activas', '$alertasActivas', AppTheme.red),
                      _buildSummaryCard('Zonas online', '$zonasOnline/${docs.length}', AppTheme.green),
                      _buildSummaryCard('Aforo medio', '${docs.isEmpty ? 0 : (totalPersonas / (docs.length * 30) * 100).toInt()}%', Colors.white),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text('ZONAS', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 15),

                  // Grid de Zonas (Aquí usamos el que te funciona)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildZoneCard(data);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const Spacer(),
          Text(value, style: TextStyle(color: valueColor, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> data) {
    final estado = data['estado'] ?? {};
    final objetivos = data['objetivos'] ?? {};
    final String nombre = data['nombre'] ?? 'Sin nombre';
    
    int actual = estado['objetos']?['person'] ?? 0;
    int limite = objetivos['person'] ?? 1;
    bool online = estado['online'] ?? false;
    
    double porcentaje = (actual / limite) * 100;
    
    Color statusColor = AppTheme.green;
    if (!online) {
      statusColor = AppTheme.textMuted.withOpacity(0.3);
    } else if (porcentaje >= 100) {
      statusColor = AppTheme.red;
    } else if (porcentaje >= 80) {
      statusColor = AppTheme.amber;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (online) ...[
                const CircleAvatar(radius: 4, backgroundColor: AppTheme.green),
                const SizedBox(width: 5),
                const Text('Live', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ] else 
                const Text('Offline', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.videocam, color: AppTheme.textMuted, size: 30),
          const Spacer(),
          Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          Text(
            online ? '$actual p - ${porcentaje.toInt()}%' : 'Sin señal',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}