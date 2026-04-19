import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_final_2dam/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String name = "User";
  bool isLoading = true;

  final String adminUid = "ZEIVxL1ulzQHEqMvZ2CMb0RKzuo1";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        name = "User";
        isLoading = false;
      });
      return;
    }

    setState(() {
      name = user.email!.split("@")[0];
      isLoading = false;
    });
  }

  bool get isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid == adminUid;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        actions: [
          Center(
            child: Text(
              "Hi, $name",
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
                ),
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

              if (isAdmin)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'admin');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(color: Colors.black),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
