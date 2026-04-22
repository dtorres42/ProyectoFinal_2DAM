import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos el UID único del usuario autenticado
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    // 2. Fecha real formateada (Requiere initializeDateFormatting en main.dart)
    String fechaReal = DateFormat("EEEE, d 'de' MMMM", 'es_ES').format(DateTime.now());
    fechaReal = fechaReal.substring(0, 1).toUpperCase() + fechaReal.substring(1);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        // PRIMER BUILDER: Busca el nombre en la colección 'usuarios' de Firestore
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
          builder: (context, userSnapshot) {
            
            // Si el documento existe usamos el campo 'name', si no "Usuario"
            String nombreUsuario = "Usuario";
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              nombreUsuario = userSnapshot.data!.get('name') ?? "Usuario";
            }
            
            String inicial = nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : "?";

            // SEGUNDO BUILDER: Escucha las estadísticas de la IA en tiempo real
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('estadisticas').doc('actual').snapshots(),
              builder: (context, statsSnapshot) {
                
                Map<String, dynamic> stats = {};
                if (statsSnapshot.hasData && statsSnapshot.data!.exists) {
                  stats = statsSnapshot.data!.data() as Map<String, dynamic>;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con Nombre, Fecha e Inicial dinámicos
                      _buildHeader(nombreUsuario, fechaReal, inicial),
                      
                      const SizedBox(height: 25),

                      // Vista de cámara / Preview
                      _buildCameraPreview(),

                      const SizedBox(height: 25),

                      // Grid de Estado Actual (Datos de la IA)
                      const Text(
                        'ESTADO ACTUAL', 
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)
                      ),
                      const SizedBox(height: 15),
                      
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _buildStatusCard('Personas', '${stats['personas'] ?? 0}', 'máx 30', (stats['personas'] ?? 0) > 30 ? AppTheme.red : AppTheme.green),
                          _buildStatusCard('Mochilas', '${stats['mochilas'] ?? 0}', 'máx 5', (stats['mochilas'] ?? 0) > 5 ? AppTheme.amber : AppTheme.primary),
                          _buildStatusCard('Móviles', '${stats['moviles'] ?? 0}', 'prohibido', (stats['moviles'] ?? 0) > 0 ? AppTheme.red : AppTheme.green),
                          _buildStatusCard('Tijeras', '${stats['tijeras'] ?? 0}', 'prohibido', (stats['tijeras'] ?? 0) > 0 ? AppTheme.red : AppTheme.green),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Listado de Alertas Recientes
                      const Text(
                        'ALERTAS RECIENTES', 
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)
                      ),
                      const SizedBox(height: 15),
                      _buildAlertsList(), 
                    ],
                  ),
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