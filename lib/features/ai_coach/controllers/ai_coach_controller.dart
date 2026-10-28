import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/services/gym_store.dart';
import '../models/chat_message_model.dart';

/// Controller untuk fitur AI Coach Geezus
/// Menggabungkan pemrosesan lokal log gym (ke GymStore) dan fallback ke Google Gemini API
/// Dilengkapi penanganan timeout eksplisit dan loading state otomatis
class AiCoachController extends ChangeNotifier {
  /// Konstanta API Key Gemini resmi pengguna
 static const String apiKey = String.fromEnvironment(
  'GEMINI_API_KEY', 
  defaultValue: 'YOUR_GEMINI_API_KEY_HERE',
);

  /// Model preferensi yang tersimpan lintas instance untuk respon instan
  static String _preferredModelName = 'gemini-1.5-flash';

  /// Urutan kandidat model Gemini (mengutamakan model cepat 1.5-flash & 2.0-flash, dengan fallback ke flash-latest & 3.8-flash)
  static const List<String> _candidateModels = [
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-flash-latest',
    'gemini-3.8-flash',
  ];

  String _activeModelName = _preferredModelName;
  GenerativeModel? _model;
  ChatSession? _chatSession;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String get activeModelName => _activeModelName;

  /// Helper untuk mengecek apakah API Key sudah diisi nilai valid
  static bool get isApiKeyConfigured {
    final trimmed = apiKey.trim();
    return trimmed.isNotEmpty &&
        trimmed != 'YOUR_GEMINI_API_KEY_HERE' &&
        !trimmed.startsWith('YOUR_');
  }

  AiCoachController() {
    _initGemini(_activeModelName);
    _initDefaultMessage();
  }

  /// Inisialisasi model Google Generative AI
  void _initGemini(String modelName) {
    if (!isApiKeyConfigured) {
      _model = null;
      _chatSession = null;
      return;
    }

    try {
      _activeModelName = modelName;
      _model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        systemInstruction: Content.system(
          'Kamu adalah Geezus AI Coach, asisten kebugaran, gym, nutrisi, dan lari yang profesional dan ramah. Jawablah pertanyaan user dengan singkat, padat, dan motivatif.',
        ),
      );
      _chatSession = _model!.startChat();
    } catch (e) {
      debugPrint('Error inisialisasi Gemini GenerativeModel ($modelName): $e');
      _model = null;
      _chatSession = null;
    }
  }

  /// Pesan sambutan awal dari AI Coach
  void _initDefaultMessage() {
    _messages.add(
      ChatMessage(
        text: 'Halo Bro! Selamat datang di Geezus AI Coach. 🏋️‍♂️\n\n'
            'Habis latihan apa hari ini? Kamu bisa:\n'
            '1. 📝 Catat latihan gym untuk menambah Damage Dungeon:\n'
            '   👉 *"Bench Press 40kg 3 set 10 rep"*\n'
            '2. 💬 Tanya seputar tips lari, nutrisi, atau pemulihan otot!\n'
            '   👉 *"Gimana cara recovery otot kaki setelah lari?"*',
        isUser: false,
        time: _getCurrentTime(),
      ),
    );
  }

  /// Mengirim pesan dari pengguna dengan pemrosesan hybrid:
  /// 1. Cek pola latihan gym lokal (simpan ke GymStore)
  /// 2. Jika bukan format gym, kirim ke Google Gemini API dengan batas timeout
  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    // Validasi defensive: cegah pesan kosong atau hanya whitespace
    if (trimmedText.isEmpty) return;

    // Cegah duplikasi pengiriman saat permintaan sebelumnya masih berjalan
    if (_isLoading) return;

    // 1. Tampilkan pesan user ke layar
    _messages.add(
      ChatMessage(
        text: trimmedText,
        isUser: true,
        time: _getCurrentTime(),
      ),
    );
    notifyListeners();

    // 2. Cek apakah pesan merupakan input log gym lokal
    if (_isGymLogPattern(trimmedText)) {
      _handleLocalGymLog(trimmedText);
      return;
    }

    // 3. Jika bukan log gym, teruskan ke Google Gemini AI
    await _sendToGemini(trimmedText);
  }

  /// Deteksi apakah input merupakan pola pencatatan gym (kg, set, rep)
  /// bukan pertanyaan (misal mengandung tanda tanya atau kata tanya)
  bool _isGymLogPattern(String input) {
    final lower = input.toLowerCase();

    // Jika mengandung tanda tanya atau kata tanya, utamakan sebagai pertanyaan ke AI
    if (input.contains('?')) {
      final isQuestionWord = RegExp(r'\b(gimana|bagaimana|kenapa|mengapa|berapa|apakah|apa)\b').hasMatch(lower);
      if (isQuestionWord) return false;
    }

    final hasWeight = RegExp(r'\d+(?:\.\d+)?\s*kg', caseSensitive: false).hasMatch(lower);
    final hasSet = RegExp(r'\d+\s*sets?', caseSensitive: false).hasMatch(lower);
    final hasRep = RegExp(r'\d+\s*reps?', caseSensitive: false).hasMatch(lower);

    return hasWeight && hasSet && hasRep;
  }

  /// Ekstraksi nilai log gym secara aman (defensive) dan catat ke GymStore
  void _handleLocalGymLog(String input) {
    try {
      final lower = input.toLowerCase();

      final RegExp weightReg = RegExp(r'(\d+(?:\.\d+)?)\s*kg');
      final RegExp setReg = RegExp(r'(\d+)\s*sets?');
      final RegExp repReg = RegExp(r'(\d+)\s*reps?');

      final weightMatch = weightReg.firstMatch(lower);
      final setMatch = setReg.firstMatch(lower);
      final repMatch = repReg.firstMatch(lower);

      if (weightMatch == null || setMatch == null || repMatch == null) {
        _sendFallbackFormatNotice();
        return;
      }

      final double? weight = double.tryParse(weightMatch.group(1) ?? '');
      final int? sets = int.tryParse(setMatch.group(1) ?? '');
      final int? reps = int.tryParse(repMatch.group(1) ?? '');

      // Defensive Check: Cegah angka tidak valid, negatif, NaN, atau angka ekstrim (overflow)
      if (weight == null || sets == null || reps == null ||
          weight <= 0 || weight.isNaN || weight.isInfinite ||
          sets <= 0 || sets > 100 || reps <= 0 || reps > 500 || weight > 2000) {
        _messages.add(
          ChatMessage(
            text: '⚠️ Angka beban, set, atau repetisi di luar batas wajar yang dapat dicatat.\n'
                '• Beban maksimal: 2000 kg\n'
                '• Set maksimal: 100 set\n'
                '• Repetisi maksimal: 500 rep\n'
                'Silakan periksa kembali catatan Anda.',
            isUser: false,
            time: _getCurrentTime(),
            isError: true,
          ),
        );
        notifyListeners();
        return;
      }

      // Bersihkan nama latihan dari kata-kata umum & angka
      String exerciseName = input
          .replaceAll(RegExp(r'\d+(?:\.\d+)?\s*kg', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d+\s*sets?', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d+\s*reps?', caseSensitive: false), '')
          .replaceAll(RegExp(r'\b(habis|catat|saya|latihan|hari ini)\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .trim();

      exerciseName = exerciseName.replaceAll(RegExp(r'\s+'), ' ');
      if (exerciseName.isEmpty) {
        exerciseName = 'Gym Workout';
      }

      // Simpan ke GymStore terpusat (notifikasi otomatis ke Boss Battle Screen)
      GymStore.instance.addLog(exerciseName, weight, sets, reps);

      final double addedVolume = weight * sets * reps;
      final int addedDamage = (addedVolume * 0.08).round();

      _messages.add(
        ChatMessage(
          text: '🔥 *LATIHAN TERCATAT KE DUNGEON!*\n\n'
              '• Latihan: ${exerciseName.toUpperCase()}\n'
              '• Beban & Reps: $weight kg ($sets set x $reps rep)\n'
              '• Volume Tambahan: +${addedVolume.toInt()} kg\n\n'
              '⚡ *+$addedDamage Damage* berhasil ditambahkan ke Boss Dungeon!',
          isUser: false,
          time: _getCurrentTime(),
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error pemrosesan log gym: $e');
      _sendFallbackFormatNotice();
    }
  }

  void _sendFallbackFormatNotice() {
    _messages.add(
      ChatMessage(
        text: 'Sip bro! Agar masuk ke hitungan *Damage Dungeon*, pastikan menyertakan format **kg**, **set**, dan **rep** ya.\n\n'
            'Contoh: *"Squat 60kg 4 set 8 rep"*',
        isUser: false,
        time: _getCurrentTime(),
      ),
    );
    notifyListeners();
  }

  /// Kirim pesan pengguna ke Google Gemini API secara aman dengan batas waktu eksplisit 10 detik
  Future<void> _sendToGemini(String input) async {
    // 1. Cek apakah API Key belum dikonfigurasi
    if (!isApiKeyConfigured) {
      _messages.add(
        ChatMessage(
          text: '🤖 *Geezus AI Coach*\n\n'
              'API Key Gemini belum disetel. Silakan masukkan Google Gemini API Key Anda pada variabel `apiKey` di `lib/features/ai_coach/controllers/ai_coach_controller.dart` agar saya dapat menjawab pertanyaan bebas di luar log latihan.\n\n'
              '💡 *Tips:* Anda tetap bisa mencatat latihan gym secara lokal, contoh: *"Bench Press 40kg 3 set 10 rep"*.',
          isUser: false,
          time: _getCurrentTime(),
          isError: true,
        ),
      );
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Jalankan query dengan batas waktu eksplisit 10 detik
      final String? responseText = await _sendMessageWithFallback(input)
          .timeout(const Duration(seconds: 10));

      if (responseText != null && responseText.isNotEmpty) {
        _messages.add(
          ChatMessage(
            text: responseText,
            isUser: false,
            time: _getCurrentTime(),
          ),
        );
      } else {
        _messages.add(
          ChatMessage(
            text: 'AI Coach tidak memberikan respons teks. Silakan coba kembali pertanyaan Anda.',
            isUser: false,
            time: _getCurrentTime(),
            isError: true,
          ),
        );
      }
    } on TimeoutException {
      debugPrint('Gemini API request timed out (>10 detik)');
      // Pesan khusus ramah saat terjadi timeout sesuai instruksi
      _messages.add(
        ChatMessage(
          text: '⏱️ *Koneksi lambat/terputus. Pastikan internet Anda aktif dan silakan coba lagi.*',
          isUser: false,
          time: _getCurrentTime(),
          isError: true,
        ),
      );
    } catch (e) {
      debugPrint('Gemini API Exception: $e');
      _messages.add(
        ChatMessage(
          text: '⚠️ Terjadi kesalahan pada AI Coach: ${e.toString()}',
          isUser: false,
          time: _getCurrentTime(),
          isError: true,
        ),
      );
    } finally {
      // Pembersihan state otomatis: selalu set isLoading kembali ke false agar spinner UI berhenti
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mencoba mengirim pesan ke model aktif atau beralih ke model cadangan jika model versi lama tidak ditemukan
  /// Setiap kandidat dibatasi timeout maksimal 5 detik agar total waktu tunggu tidak melebihi 10 detik
  Future<String?> _sendMessageWithFallback(String input) async {
    Object? lastError;

    // Prioritaskan model aktif saat ini
    final modelsToTry = [
      _activeModelName,
      ..._candidateModels.where((m) => m != _activeModelName),
    ];

    for (final modelName in modelsToTry) {
      try {
        if (_model == null || _chatSession == null || _activeModelName != modelName) {
          _initGemini(modelName);
        }

        if (_chatSession == null) continue;

        // Batasi timeout tiap percobaan kandidat maksimal 5 detik
        final response = await _chatSession!
            .sendMessage(Content.text(input))
            .timeout(const Duration(seconds: 5));

        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) {
          _activeModelName = modelName;
          _preferredModelName = modelName;
          return text;
        }
      } catch (e) {
        lastError = e;
        debugPrint('Model $modelName gagal/timeout: $e. Mencoba model berikutnya...');
        final errLower = e.toString().toLowerCase();

        // Lanjut ke model berikutnya jika error terkait model not found / deprecated / unavailable / 503 / timeout
        if (errLower.contains('not found') ||
            errLower.contains('no longer available') ||
            errLower.contains('not supported') ||
            errLower.contains('503') ||
            errLower.contains('unavailable') ||
            e is TimeoutException) {
          continue;
        } else {
          // Jika error autentikasi, invalid API key, atau exception fatal lain, langsung lempar
          rethrow;
        }
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    return null;
  }

  /// Bersihkan riwayat chat dan mulai percakapan baru
  void clearMessages() {
    _messages.clear();
    _chatSession = _model?.startChat();
    _initDefaultMessage();
    notifyListeners();
  }

  /// Format waktu saat ini (HH:mm)
  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
