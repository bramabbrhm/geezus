import 'package:flutter/material.dart';
import '../../../../core/services/gym_store.dart';
import '../controllers/ai_coach_controller.dart';
import '../models/chat_message_model.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  late final AiCoachController _coachController;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _coachController = AiCoachController();
    _coachController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _coachController.removeListener(_onControllerUpdate);
    _coachController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Mengirim pesan dengan validasi defensive di sisi UI
  void _handleSend() {
    if (_coachController.isLoading) return;
    final text = _textController.text;
    // Validasi: input kosong atau hanya whitespace tidak bisa dikirim
    if (text.trim().isEmpty) return;

    _textController.clear();
    _coachController.sendMessage(text);
    _scrollToBottom();
  }

  /// Scroll otomatis ke posisi terbawah secara aman
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          debugPrint('Scroll error suppressed defensively: $e');
        }
      }
    });
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
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Geezus AI Coach',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _coachController.isLoading
                      ? '● Merespons...'
                      : '● Online | Gemini & Gym Sync',
                  style: TextStyle(
                    fontSize: 11,
                    color: _coachController.isLoading
                        ? Colors.amberAccent
                        : Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mulai Ulang Percakapan',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => _coachController.clearMessages(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Real-Time Volume (terkoneksi langsung dengan GymStore)
            AnimatedBuilder(
              animation: GymStore.instance,
              builder: (context, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: _cardColor.withValues(alpha: 0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text(
                          '🏋️ Total Volume Gym Terakumulasi:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
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

            // Daftar Percakapan Chat
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _coachController.messages.length +
                    (_coachController.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _coachController.messages.length) {
                    return _buildTypingIndicator();
                  }

                  final msg = _coachController.messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Bar Input Teks
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
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Tanya coach atau catat (e.g. Squat 60kg 4 set 8 rep)...',
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: Colors.black26,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: _primaryColor,
                      disabledBackgroundColor: _primaryColor.withValues(alpha: 0.3),
                    ),
                    icon: _coachController.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                    onPressed: _coachController.isLoading ? null : _handleSend,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bubble pesan interaktif
  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    final isError = msg.isError;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    Color bubbleColor;
    if (isUser) {
      bubbleColor = _primaryColor;
    } else if (isError) {
      bubbleColor = const Color(0xFF2C1E1E);
    } else {
      bubbleColor = _cardColor;
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isError
                ? Colors.redAccent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isError ? Colors.red.shade100 : Colors.white,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              msg.time,
              style: TextStyle(
                color: isUser ? Colors.white60 : Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Indikator visual ketika AI Coach sedang merespons
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _primaryColor,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Geezus AI Coach sedang merespons...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
