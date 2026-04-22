import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    // Fecha real formateada
    String fechaReal = DateFormat("EEEE, d 'de' MMMM", 'es_ES').format(DateTime.now());
    fechaReal = fechaReal.substring(0, 1).toUpperCase() + fechaReal.substring(1);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        // 1. Buscamos el nombre del usuario en Firestore
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
          builder: (context, userSnapshot) {
            String nombreUsuario = userSnapshot.data?.get('name') ?? "Usuario";
            String inicial = nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : "?";

            // 2. Escuchamos los límites configurados en 'zonas/aula_1'
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('zonas').doc('aula_1').snapshots(),
              builder: (context, zonasSnapshot) {
                
                // Extraemos los objetivos (límites para alertas)
                var zonaData = zonasSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                var objetivos = zonaData['objetivos'] ?? {};
                
                int maxPersonas = objetivos['person'] ?? 30;
                int maxMochilas = objetivos['backpack'] ?? 5;
                int maxMoviles  = objetivos['cell phone'] ?? 0;
                int maxTijeras  = objetivos['scissors'] ?? 0;

                // 3. Escuchamos el conteo actual de la IA
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('estadisticas').doc('actual').snapshots(),
                  builder: (context, statsSnapshot) {
                    var stats = statsSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                    
                    int currentPersonas = stats['personas'] ?? 0;
                    int currentMochilas = stats['mochilas'] ?? 0;
                    int currentMoviles  = stats['moviles']  ?? 0;
                    int currentTijeras  = stats['tijeras']  ?? 0;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(nombreUsuario, fechaReal, inicial),
                          const SizedBox(height: 25),
                          _buildCameraPreview(),
                          const SizedBox(height: 25),
                          
                          const Text('ESTADO ACTUAL', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: [
                              _buildStatusCard('Personas', '$currentPersonas', 'máx $maxPersonas', currentPersonas >= maxPersonas ? AppTheme.red : AppTheme.green),
                              _buildStatusCard('Mochilas', '$currentMochilas', 'máx $maxMochilas', currentMochilas >= maxMochilas ? AppTheme.amber : AppTheme.primary),
                              _buildStatusCard('Móviles', '$currentMoviles', 'máx $maxMoviles', currentMoviles > maxMoviles ? AppTheme.red : AppTheme.green),
                              _buildStatusCard('Tijeras', '$currentTijeras', 'máx $maxTijeras', currentTijeras > maxTijeras ? AppTheme.red : AppTheme.green),
                            ],
                          ),
                          
                          const SizedBox(height: 30),
                          const Text('ALERTAS RECIENTES', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          _buildAlertsList(),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // --- COMPONENTES DE INTERFAZ ---

  Widget _buildHeader(String nombre, String fecha, String inicial) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bienvenido, $nombre', 
                style: const TextStyle(color: AppTheme.textPrim, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(fecha, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          ],
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primary,
          child: Text(inicial, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.videocam_off_outlined, color: AppTheme.textMuted, size: 40)),
          Positioned(
            top: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.fiber_manual_record, color: AppTheme.green, size: 10),
                  SizedBox(width: 4),
                  Text('Live', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 20,
            left: 20,
            child: Text('Aula 1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppTheme.textPrim, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(sub, style: TextStyle(color: (sub == 'prohibido' && value != '0') ? AppTheme.red : AppTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alertas').orderBy('fecha', descending: true).limit(3).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No hay alertas hoy', style: TextStyle(color: AppTheme.textMuted));
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final alert = doc.data() as Map<String, dynamic>;
            return _buildAlertTile(
              '${alert['objeto'] ?? 'Detección'} — ${alert['aula'] ?? 'Aula 1'}',
              alert['descripcion'] ?? 'Objeto no permitido',
              alert['estado'] == 'activa' ? 'Gestionar' : 'Resuelta',
              alert['estado'] == 'activa' ? AppTheme.red : AppTheme.green,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAlertTile(String title, String desc, String btnLabel, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrim, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(btnLabel, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}