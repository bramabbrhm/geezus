// ignore_for_file: avoid_dynamic_calls
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys for SharedPreferences persistence
const _kHydrationEnabled = 'notif_hydration_enabled';
const _kHydrationIntervalHours = 'notif_hydration_interval_hours';
const _kRunEnabled = 'notif_run_enabled';
const _kRunHour = 'notif_run_hour';
const _kRunMinute = 'notif_run_minute';

// Stable notification IDs to prevent duplicates
const _kHydrationNotifId = 100;
const _kRunNotifId = 101;
const _kHydrationTestId = 300;
const _kRunTestId = 301;

// Single lazy instance stored as `dynamic` to bypass web stub type conflicts.
// All NotificationService methods share this same instance so that
// initialize() and show()/periodicallyShow() operate on the same object.
dynamic _sharedPlugin;

dynamic _plugin() {
  if (kIsWeb) return null;
  _sharedPlugin ??= FlutterLocalNotificationsPlugin();
  return _sharedPlugin;
}

/// Result of a permission check/request.
enum NotifPermissionStatus {
  /// Permission granted — can send notification.
  granted,

  /// Permission denied but can still ask (first-time or rationale).
  denied,

  /// Permission permanently denied — user must go to app Settings.
  permanentlyDenied,

  /// Platform not supported (web).
  unsupported,
}

class NotificationService {
  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  static Future<void> initNotification() async {
    if (kIsWeb) {
      debugPrint('NotificationService: skipped on Web platform.');
      return;
    }
    final p = _plugin();
    if (p == null) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await p.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Create Android notification channels with MAX importance for heads-up
      final typed = p as FlutterLocalNotificationsPlugin;
      final androidPlugin = typed
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'hydration_channel',
            'Pengingat Hidrasi',
            description: 'Notifikasi jadwal minum air putih harian',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'run_reminder_channel',
            'Jadwal Lari Harian',
            description: 'Notifikasi pengingat aktivitas lari harian',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }

      // Restore previously scheduled notifications after app restart
      await _restoreScheduledNotifications();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  static void _onNotificationResponse(NotificationResponse details) {
    debugPrint('Notification tapped: ${details.payload}');
  }

  // ---------------------------------------------------------------------------
  // Permission Handling — uses permission_handler for reliable Android support
  // ---------------------------------------------------------------------------

  /// Check current notification permission status.
  static Future<NotifPermissionStatus> getPermissionStatus() async {
    if (kIsWeb) return NotifPermissionStatus.unsupported;
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return NotifPermissionStatus.granted;
      if (status.isPermanentlyDenied) {
        return NotifPermissionStatus.permanentlyDenied;
      }
      return NotifPermissionStatus.denied;
    } catch (e) {
      debugPrint('getPermissionStatus error: $e');
      return NotifPermissionStatus.denied;
    }
  }

  /// Request notification permission.
  /// Returns the resulting [NotifPermissionStatus].
  static Future<NotifPermissionStatus> requestPermission() async {
    if (kIsWeb) return NotifPermissionStatus.unsupported;
    try {
      final current = await Permission.notification.status;
      if (current.isGranted) {
        debugPrint('Notification permission: already granted');
        return NotifPermissionStatus.granted;
      }
      if (current.isPermanentlyDenied) {
        debugPrint('Notification permission: permanently denied — open settings');
        return NotifPermissionStatus.permanentlyDenied;
      }
      // Request the permission — shows OS dialog
      final result = await Permission.notification.request();
      debugPrint('Notification permission request result: $result');
      if (result.isGranted) return NotifPermissionStatus.granted;
      if (result.isPermanentlyDenied) return NotifPermissionStatus.permanentlyDenied;
      return NotifPermissionStatus.denied;
    } catch (e) {
      debugPrint('requestPermission error: $e');
      return NotifPermissionStatus.denied;
    }
  }

  /// Open the app's notification settings page so the user can toggle it on.
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Simple bool check — true if permission is currently granted.
  static Future<bool> checkPermission() async {
    if (kIsWeb) return false;
    final status = await getPermissionStatus();
    return status == NotifPermissionStatus.granted;
  }

  // ---------------------------------------------------------------------------
  // Hydration Reminder
  // ---------------------------------------------------------------------------

  /// Schedule hourly hydration reminder. Cancels any existing one first.
  static Future<void> scheduleHydrationReminder(int intervalHours) async {
    if (kIsWeb) return;
    final p = _plugin();
    if (p == null) return;
    await cancelHydrationReminder();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHydrationEnabled, true);
      await prefs.setInt(_kHydrationIntervalHours, intervalHours);

      await p.periodicallyShow(
        _kHydrationNotifId,
        '💧 Waktunya Minum Air!',
        'Jaga hidrasi tubuhmu. Minum 1-2 gelas air sekarang.',
        RepeatInterval.hourly,
        _buildNotifDetails(
          channelId: 'hydration_channel',
          channelName: 'Pengingat Hidrasi',
          body: 'Jaga hidrasi tubuhmu. Minum 1-2 gelas air sekarang.',
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'hydration_screen',
      );
      debugPrint('Hydration reminder scheduled (${intervalHours}h interval)');
    } catch (e) {
      debugPrint('scheduleHydrationReminder error: $e');
    }
  }

  /// Cancel hydration reminder and persist OFF state.
  static Future<void> cancelHydrationReminder() async {
    if (kIsWeb) return;
    final p = _plugin();
    if (p == null) return;
    try {
      await p.cancel(_kHydrationNotifId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHydrationEnabled, false);
    } catch (e) {
      debugPrint('cancelHydrationReminder error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Run Reminder
  // ---------------------------------------------------------------------------

  /// Schedule daily run reminder.
  static Future<void> scheduleRunReminder(int hour, int minute) async {
    if (kIsWeb) return;
    final p = _plugin();
    if (p == null) return;
    await cancelRunReminder();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRunEnabled, true);
      await prefs.setInt(_kRunHour, hour);
      await prefs.setInt(_kRunMinute, minute);

      await p.periodicallyShow(
        _kRunNotifId,
        '🏃 Siap Lari Hari Ini?',
        'Boss Mingguan menunggu! Kumpulkan EXP lari sekarang.',
        RepeatInterval.daily,
        _buildNotifDetails(
          channelId: 'run_reminder_channel',
          channelName: 'Jadwal Lari Harian',
          body: 'Boss Mingguan menunggu! Kumpulkan EXP lari sekarang.',
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'run_screen',
      );
      debugPrint(
          'Run reminder scheduled ($hour:${minute.toString().padLeft(2, '0')})');
    } catch (e) {
      debugPrint('scheduleRunReminder error: $e');
    }
  }

  /// Cancel run reminder and persist OFF state.
  static Future<void> cancelRunReminder() async {
    if (kIsWeb) return;
    final p = _plugin();
    if (p == null) return;
    try {
      await p.cancel(_kRunNotifId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRunEnabled, false);
    } catch (e) {
      debugPrint('cancelRunReminder error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Immediate Test Notifications
  // ---------------------------------------------------------------------------

  /// Send immediate hydration test notification.
  /// Returns [NotifPermissionStatus] so the caller can react appropriately.
  static Future<NotifPermissionStatus> showHydrationReminder() async {
    if (kIsWeb) return NotifPermissionStatus.unsupported;
    final p = _plugin();
    if (p == null) return NotifPermissionStatus.unsupported;

    final status = await requestPermission();
    if (status != NotifPermissionStatus.granted) return status;

    try {
      await p.show(
        _kHydrationTestId,
        '💧 Waktunya Minum Air!',
        'Jaga hidrasi tubuhmu. Minum 1-2 gelas air sekarang.',
        _buildNotifDetails(
          channelId: 'hydration_channel',
          channelName: 'Pengingat Hidrasi',
          body: 'Jaga hidrasi tubuhmu. Minum 1-2 gelas air sekarang.',
        ),
        payload: 'hydration_screen',
      );
      debugPrint('Hydration test notification sent');
      return NotifPermissionStatus.granted;
    } catch (e) {
      debugPrint('showHydrationReminder error: $e');
      return NotifPermissionStatus.denied;
    }
  }

  /// Send immediate run test notification.
  /// Returns [NotifPermissionStatus] so the caller can react appropriately.
  static Future<NotifPermissionStatus> showRunReminder() async {
    if (kIsWeb) return NotifPermissionStatus.unsupported;
    final p = _plugin();
    if (p == null) return NotifPermissionStatus.unsupported;

    final status = await requestPermission();
    if (status != NotifPermissionStatus.granted) return status;

    try {
      await p.show(
        _kRunTestId,
        '🏃 Siap Lari Hari Ini?',
        'Boss Mingguan menunggu! Kumpulkan EXP larimu sekarang.',
        _buildNotifDetails(
          channelId: 'run_reminder_channel',
          channelName: 'Jadwal Lari Harian',
          body: 'Boss Mingguan menunggu! Kumpulkan EXP larimu sekarang.',
        ),
        payload: 'run_screen',
      );
      debugPrint('Run test notification sent');
      return NotifPermissionStatus.granted;
    } catch (e) {
      debugPrint('showRunReminder error: $e');
      return NotifPermissionStatus.denied;
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence helpers
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'hydration_enabled': prefs.getBool(_kHydrationEnabled) ?? false,
      'hydration_interval_hours': prefs.getInt(_kHydrationIntervalHours) ?? 2,
      'run_enabled': prefs.getBool(_kRunEnabled) ?? false,
      'run_hour': prefs.getInt(_kRunHour) ?? 7,
      'run_minute': prefs.getInt(_kRunMinute) ?? 0,
    };
  }

  static Future<void> _restoreScheduledNotifications() async {
    final settings = await loadSettings();
    if (settings['hydration_enabled'] == true) {
      await scheduleHydrationReminder(
          settings['hydration_interval_hours'] as int);
    }
    if (settings['run_enabled'] == true) {
      await scheduleRunReminder(
          settings['run_hour'] as int, settings['run_minute'] as int);
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static NotificationDetails _buildNotifDetails({
    required String channelId,
    required String channelName,
    String body = '',
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        // MAX importance + priority → heads-up (popup) notification
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: null,
          htmlFormatBigText: false,
        ),
        ticker: 'Geezus',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
