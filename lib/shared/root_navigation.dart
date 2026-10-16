import 'package:flutter/material.dart';
import '../features/boss_battle/views/boss_battle_screen.dart';
import '../features/tracking/views/live_run_screen.dart';

class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LiveRunScreen(),
    BossBattleScreen(), // Tab Mini-Game Boss Battle
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E1E2C),
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Run'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'Boss Battle'),
        ],
      ),
    );
  }
}