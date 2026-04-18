import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BottomNavBar extends StatelessWidget {
  final String currentRoute;

  const BottomNavBar({super.key, required this.currentRoute});

  void _navigate(BuildContext context, String route) {
    if (currentRoute == route) return;
    Navigator.pushReplacementNamed(context, route);
  }

  Widget _buildNavIcon(
    BuildContext context,
    IconData outlineIcon,
    IconData solidIcon,
    String route,
  ) {
    bool isSelected = currentRoute == route;
    return IconButton(
      icon: Icon(
        isSelected ? solidIcon : outlineIcon,
        color: Colors.white,
        size: isSelected ? 28 : 24,
      ),
      onPressed: () => _navigate(context, route),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    bool isSelected = currentRoute == 'notifications';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("alertas")
          .where("leida", isEqualTo: false)
          .where("estado", isEqualTo: "activa")
          .snapshots(),
      builder: (context, snapshot) {
        final tieneAlertas = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                isSelected ? Icons.notifications : Icons.notifications_none,
                color: Colors.white,
                size: isSelected ? 28 : 24,
              ),
              onPressed: () => _navigate(context, 'notifications'),
            ),
            if (tieneAlertas)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xFF0088FF),
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavIcon(context, Icons.home_outlined, Icons.home, 'home'),
            _buildNavIcon(
              context,
              Icons.videocam_outlined,
              Icons.videocam,
              'cameras',
            ),
            const SizedBox(width: 40),
            _buildNotificationIcon(context),
            _buildNavIcon(
              context,
              Icons.person_outline,
              Icons.person,
              'profile',
            ),
          ],
        ),
      ),
    );
  }
}
