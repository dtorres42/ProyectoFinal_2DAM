import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  const HomeScreen({super.key, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAdmin() {
    String name = widget.email.split("@")[0];
    return name.toLowerCase() == "admin";
  }

  String _getUserName() {
    if (widget.email.isEmpty) return "User";
    String name = widget.email.split("@")[0];
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        actions: [
          Center(
            child: Text(
              "Hi, ${_getUserName()}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 15),
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blueGrey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 20),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentRoute: 'home'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF006BCC),
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
                    ),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "Live",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.arrow_back_ios, size: 14, color: Colors.black54),
                  SizedBox(width: 20),
                  Text(
                    "Indoor",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 20),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.black54,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                "Recent Motion",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 15),
              const AlertListTile(
                bgColor: Color(0xFF86C5FF),
                icon: Icons.directions_walk,
                title: "Movement Detected",
                subtitle: "AAAAAAAAAAAAA",
                time: "10:32 AM",
              ),
              const AlertListTile(
                bgColor: Color(0xFFFFEB5C),
                icon: Icons.warning_amber_rounded,
                title: "Movement Detected",
                subtitle: "BBBBBBBBBBB",
                time: "10:32 AM",
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, 'admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text('Admin', style: TextStyle(color: Colors.black)),
              ),

              const SizedBox(height: 20),
              if (isAdmin()) ...[
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, 'admin');
                    },
                    child: const Text(
                      "Panel de administración",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
