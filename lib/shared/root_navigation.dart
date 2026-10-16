import 'package:flutter/material.dart';
import '../features/tracking/views/live_run_screen.dart';
import '../features/boss_battle/views/boss_battle_screen.dart';
import '../features/ai_coach/views/ai_coach_screen.dart';
// import '../features/web3_nft/views/badges_screen.dart'; // Comment
import '../features/auth/views/profile_screen.dart';

class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  int _selectedIndex = 0;

  // Total ada 4 screen (Indeks 0, 1, 2, 3)
  final List<Widget> _screens = const [
    LiveRunScreen(),    // Index 0
    BossBattleScreen(), // Index 1
    AiCoachScreen(),    // Index 2
    ProfileScreen(),     // Index 3 (Profile sekarang di posisi ini)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E2C),
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey,
        // Total items WAJIB 4 pasang sesuai _screens
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Run'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'Boss'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'AI Coach'),
          // BottomNavigationBarItem(icon: Icon(Icons.military_tech), label: 'Web3 NFT'), // WAJIB DI-COMMENT
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}