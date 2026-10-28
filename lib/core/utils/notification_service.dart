import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Inisialisasi Layanan Notifikasi
  static Future<void> initNotification() async {
    // Abaikan eksekusi jika dijalankan di Browser / Chrome Web
    if (kIsWeb) {
      debugPrint(
        'NotificationService: Fitur notifikasi dilewati pada platform Web.',
      );
      return;
    }

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      // Menggunakan dynamic agar kompilator Web tidak bentrok dengan stub signature
      final dynamic plugin = _notificationsPlugin;
      await plugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notifikasi diklik: ${details.payload}');
        },
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error inisialisasi notifikasi: $e');
    }
  }

  // Notifikasi Pengingat Minum Air
  static Future<void> showHydrationReminder() async {
    if (kIsWeb) {
      debugPrint(
        'NotificationService: Notifikasi lokal hanya berjalan di Android / iOS.',
      );
      return;
    }

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'hydration_channel',
            'Pengingat Hidrasi',
            channelDescription: 'Notifikasi jadwal minum air putih harian',
            importance: Importance.high,
            priority: Priority.high,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      final dynamic plugin = _notificationsPlugin;
      await plugin.show(
        100,
        'Waktunya Minum Air! 💧',
        'Jaga hidrasi tubuhmu setelah atau sebelum sesi lari.',
        notificationDetails,
        payload: 'hydration_screen',
      );
    } catch (e) {
      debugPrint('Error mengirim notifikasi hidrasi: $e');
    }
  }

  // Notifikasi Pengingat Jadwal Lari Harian
  static Future<void> showRunReminder() async {
    if (kIsWeb) {
      debugPrint(
        'NotificationService: Notifikasi lokal hanya berjalan di Android / iOS.',
      );
      return;
    }

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'run_reminder_channel',
            'Jadwal Lari Harian',
            channelDescription: 'Notifikasi pengingat aktivitas lari harian',
            importance: Importance.max,
            priority: Priority.high,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      final dynamic plugin = _notificationsPlugin;
      await plugin.show(
        101,
        'Siap Untuk Lari Hari Ini? 🏃‍♂️',
        'Boss Mingguan menunggu! Kumpulkan EXP lari kamu sekarang.',
        notificationDetails,
        payload: 'run_screen',
      );
    } catch (e) {
      debugPrint('Error mengirim notifikasi lari: $e');
    }
  }
}
