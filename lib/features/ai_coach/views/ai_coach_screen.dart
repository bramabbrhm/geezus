import 'package:flutter/material.dart';
import '../../../../core/services/gym_store.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'ai',
      'text': 'Halo Bro! Selamat datang di Geezus. 🏋️‍♂️\n\n'
          'Habis latihan apa hari ini? Ketik nama latihan, beban, set, dan rep-nya. Contoh:\n'
          '👉 "Habis Bench Press 40kg 3 set 10 rep"',
      'time': '10:00 AM',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userText = text.trim();
    _controller.clear();

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': userText,
        'time': _getCurrentTime(),
      });
    });

    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _processAiResponse(userText);
      _scrollToBottom();
    });
  }

  void _processAiResponse(String input) {
    final lower = input.toLowerCase();

    final RegExp weightReg = RegExp(r'(\d+(\.\d+)?)\s*kg');
    final RegExp setReg = RegExp(r'(\d+)\s*set');
    final RegExp repReg = RegExp(r'(\d+)\s*rep');

    final weightMatch = weightReg.firstMatch(lower);
    final setMatch = setReg.firstMatch(lower);
    final repMatch = repReg.firstMatch(lower);

    if (weightMatch != null && setMatch != null && repMatch != null) {
      double weight = double.parse(weightMatch.group(1)!);
      int sets = int.parse(setMatch.group(1)!);
      int reps = int.parse(repMatch.group(1)!);

      // Ambil nama gerakan (bersihkan kata angka/kg/set/rep)
      String exerciseName = input
          .replaceAll(RegExp(r'\d+(\.\d+)?\s*kg|\d+\s*set|\d+\s*rep|habis|catat|saya', caseSensitive: false), '')
          .trim();
      if (exerciseName.isEmpty) exerciseName = 'Gym Workout';

      // Simpan ke GymStore terpusat agar Damage Boss bertambah!
      GymStore.instance.addLog(exerciseName, weight, sets, reps);

      double addedVolume = weight * sets * reps;

      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': '🔥 *LATIHAN TERCATAT KE DUNGEON!*\n\n'
              '• Latihan: ${exerciseName.toUpperCase()}\n'
              '• Beban & Reps: $weight kg ($sets set x $reps rep)\n'
              '• Volume Tambahan: +${addedVolume.toInt()} kg\n\n'
              '⚡ *+${(addedVolume * 0.08).round()} Damage* berhasil ditambahkan ke Boss Dungeon!',
          'time': _getCurrentTime(),
        });
      });
    } else {
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': 'Sip bro! Agar masuk ke hitungan *Damage Dungeon*, pastikan menyertakan format **kg**, **set**, dan **rep** ya.\n\n'
              'Contoh: *"Squat 60kg 4 set 8 rep"*',
          'time': _getCurrentTime(),
        });
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Geezus AI Coach',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '● Online | Dynamic Damage Active',
                  style: TextStyle(fontSize: 11, color: Colors.greenAccent),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Real-Time Volume
            AnimatedBuilder(
              animation: GymStore.instance,
              builder: (context, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: _cardColor.withOpacity(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🏋️ Total Volume Gym Terakumulasi:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${GymStore.instance.totalVolumeKg.toInt()} kg',
                      style: const TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: isUser ? _primaryColor : _cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['text'],
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: _cardColor,
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Bench Press 40kg 3 set 10 rep...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        filled: true,
                        fillColor: Colors.black26,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: _primaryColor),
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}