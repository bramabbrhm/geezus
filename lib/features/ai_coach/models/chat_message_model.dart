/// Model data untuk pesan chat pada modul AI Coach
class ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isError = false,
  });

  /// Factory untuk menyalin objek dengan perubahan tertentu (immutability)
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    String? time,
    bool? isError,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      time: time ?? this.time,
      isError: isError ?? this.isError,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(isUser: $isUser, time: $time, isError: $isError, text: $text)';
  }
}

