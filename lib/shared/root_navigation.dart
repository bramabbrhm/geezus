import 'package:flutter/material.dart';
import '../features/ai_coach/views/ai_coach_screen.dart';
import '../features/boss_battle/views/boss_battle_screen.dart';
import '../features/tracking/views/live_run_screen.dart';
import '../features/auth/views/profile_screen.dart';

class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  int _currentIndex = 0;

  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  final List<Widget> _screens = const [
    AiCoachScreen(),
    BossBattleScreen(),
    LiveRunScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: _cardColor,
          indicatorColor: _primaryColor.withOpacity(0.3),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return const TextStyle(color: Colors.white54, fontSize: 12);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.smart_toy_rounded, color: _primaryColor),
              label: 'AI Coach',
            ),
            NavigationDestination(
              icon: Icon(Icons.shield_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.shield, color: _primaryColor),
              label: 'Dungeon',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.map_rounded, color: _primaryColor),
              label: 'Tracking',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.white54),
              selectedIcon: Icon(Icons.person, color: _primaryColor),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}