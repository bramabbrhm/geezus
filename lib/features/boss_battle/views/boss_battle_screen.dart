import 'package:flutter/material.dart';

class BossBattleScreen extends StatelessWidget {
  const BossBattleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Boss Raid'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF1E1E2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.bug_report, size: 100, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    const Text('MECHA TITAN BOSS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(value: 0.65, color: Colors.redAccent, backgroundColor: Colors.black26, minHeight: 12),
                    const SizedBox(height: 6),
                    const Text('HP: 65,000 / 100,000', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2B55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Workout Power Boost:'),
                  Text('+4,820 DMG', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00FFA3))),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.flash_on, color: Colors.white),
                label: const Text('ATTACK BOSS', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}