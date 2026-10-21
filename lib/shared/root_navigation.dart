import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../features/tracking/views/live_run_screen.dart';
import '../features/boss_battle/views/boss_battle_screen.dart';
import '../features/ai_coach/views/ai_coach_screen.dart';
// import '../features/web3_nft/views/badges_screen.dart'; // Comment
=======
import '../features/ai_coach/views/ai_coach_screen.dart';
import '../features/boss_battle/views/boss_battle_screen.dart';
import '../features/tracking/views/live_run_screen.dart';
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
import '../features/auth/views/profile_screen.dart';

class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
<<<<<<< HEAD
  int _selectedIndex = 0;

  // Total ada 4 screen (Indeks 0, 1, 2, 3)
  final List<Widget> _screens = const [
    LiveRunScreen(),    // Index 0
    BossBattleScreen(), // Index 1
    AiCoachScreen(),    // Index 2
    ProfileScreen(),     // Index 3 (Profile sekarang di posisi ini)
=======
  int _currentIndex = 0;

  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  final List<Widget> _screens = const [
    AiCoachScreen(),
    BossBattleScreen(),
    LiveRunScreen(),
    ProfileScreen(),
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
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
=======
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
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
      ),
    );
  }
}