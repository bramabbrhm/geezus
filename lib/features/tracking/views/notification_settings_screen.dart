// ignore_for_file: deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  bool _loading = true;
  NotifPermissionStatus _permStatus = NotifPermissionStatus.denied;

  // Hydration settings
  bool _hydrationEnabled = false;
  int _hydrationIntervalHours = 2;

  // Run reminder settings
  bool _runEnabled = false;
  int _runHour = 7;
  int _runMinute = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final status = kIsWeb
        ? NotifPermissionStatus.unsupported
        : await NotificationService.getPermissionStatus();
    final settings = await NotificationService.loadSettings();

    if (!mounted) return;
    setState(() {
      _permStatus = status;
      _hydrationEnabled = settings['hydration_enabled'] as bool;
      _hydrationIntervalHours = settings['hydration_interval_hours'] as int;
      _runEnabled = settings['run_enabled'] as bool;
      _runHour = settings['run_hour'] as int;
      _runMinute = settings['run_minute'] as int;
      _loading = false;
    });
  }

  /// Request permission; updates banner. Shows OS dialog on first ask,
  /// routes to Settings if permanently denied.
  Future<bool> _askPermission() async {
    if (kIsWeb) return false;
    final result = await NotificationService.requestPermission();
    if (!mounted) return false;
    setState(() => _permStatus = result);

    switch (result) {
      case NotifPermissionStatus.granted:
        _showSnack('✅ Izin notifikasi berhasil diberikan!');
        return true;
      case NotifPermissionStatus.permanentlyDenied:
        _showPermanentlyDeniedDialog();
        return false;
      default:
        _showSnack('❌ Izin notifikasi ditolak.');
        return false;
    }
  }

  void _showPermanentlyDeniedDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Izin Diperlukan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Izin notifikasi ditolak secara permanen.\n\n'
          'Buka Pengaturan Aplikasi → Notifikasi, lalu aktifkan izin notifikasi untuk Geezus.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () {
              Navigator.pop(ctx);
              NotificationService.openSettings();
            },
            child: const Text('Buka Pengaturan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleHydration(bool value) async {
    if (kIsWeb) { _showWebUnsupportedSnack(); return; }
    if (value) {
      final ok = await _askPermission();
      if (!ok) return;
    }
    if (value) {
      await NotificationService.scheduleHydrationReminder(_hydrationIntervalHours);
    } else {
      await NotificationService.cancelHydrationReminder();
    }
    if (mounted) setState(() => _hydrationEnabled = value);
    _showSnack(value ? '💧 Pengingat hidrasi diaktifkan' : '💧 Pengingat hidrasi dimatikan');
  }

  Future<void> _toggleRun(bool value) async {
    if (kIsWeb) { _showWebUnsupportedSnack(); return; }
    if (value) {
      final ok = await _askPermission();
      if (!ok) return;
    }
    if (value) {
      await NotificationService.scheduleRunReminder(_runHour, _runMinute);
    } else {
      await NotificationService.cancelRunReminder();
    }
    if (mounted) setState(() => _runEnabled = value);
    _showSnack(value ? '🏃 Pengingat lari diaktifkan' : '🏃 Pengingat lari dimatikan');
  }

  Future<void> _pickHydrationInterval() async {
    final intervals = [1, 2, 3, 4, 6, 8, 12];
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Interval Pengingat Hidrasi',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals
              .map((h) => RadioListTile<int>(
                    value: h,
                    groupValue: _hydrationIntervalHours,
                    activeColor: _primaryColor,
                    title: Text(
                      h == 1 ? 'Setiap 1 jam' : 'Setiap $h jam',
                      style: const TextStyle(color: Colors.white),
                    ),
                    onChanged: (v) => Navigator.pop(ctx, v),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked != null && picked != _hydrationIntervalHours) {
      setState(() => _hydrationIntervalHours = picked);
      if (_hydrationEnabled) {
        await NotificationService.scheduleHydrationReminder(picked);
        _showSnack('Interval diperbarui: setiap $picked jam');
      }
    }
  }

  Future<void> _pickRunTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _runHour, minute: _runMinute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: _primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (!mounted || picked == null) return;
    if (picked.hour != _runHour || picked.minute != _runMinute) {
      final formattedTime = picked.format(context);
      setState(() {
        _runHour = picked.hour;
        _runMinute = picked.minute;
      });
      if (_runEnabled) {
        await NotificationService.scheduleRunReminder(_runHour, _runMinute);
        _showSnack('Waktu pengingat lari diperbarui: $formattedTime');
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _primaryColor,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showWebUnsupportedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.deepOrange,
        content: Text(
          '⚠️ Notifikasi lokal tidak didukung di platform Web.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Permission status banner ─────────────────────────────
                  _buildPermissionBanner(),

                  const SizedBox(height: 20),

                  // ── Hydration ────────────────────────────────────────────
                  _buildSectionHeader('💧 Pengingat Hidrasi'),
                  const SizedBox(height: 8),
                  _buildCard(
                    children: [
                      SwitchListTile(
                        activeColor: _primaryColor,
                        value: _hydrationEnabled,
                        onChanged: kIsWeb ? null : _toggleHydration,
                        title: const Text('Aktifkan Pengingat Minum Air',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          _hydrationEnabled
                              ? 'Aktif — setiap $_hydrationIntervalHours jam'
                              : 'Nonaktif',
                          style: TextStyle(
                            color: _hydrationEnabled
                                ? Colors.lightBlueAccent
                                : Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        secondary: const Icon(Icons.water_drop,
                            color: Colors.lightBlueAccent),
                      ),
                      if (_hydrationEnabled) ...[
                        const Divider(color: Colors.white10),
                        ListTile(
                          leading: const Icon(Icons.timer, color: Colors.white54),
                          title: const Text('Interval Pengingat',
                              style: TextStyle(color: Colors.white)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Setiap $_hydrationIntervalHours jam',
                                style: const TextStyle(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right,
                                  color: Colors.white38, size: 18),
                            ],
                          ),
                          onTap: _pickHydrationInterval,
                        ),
                      ],
                      const Divider(color: Colors.white10),
                      _buildTestTile(
                        icon: Icons.send,
                        iconColor: Colors.lightBlueAccent,
                        buttonColor: Colors.lightBlue.shade700,
                        onTest: () async {
                          final result =
                              await NotificationService.showHydrationReminder();
                          _handleTestResult(result, 'hidrasi');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Run Reminder ─────────────────────────────────────────
                  _buildSectionHeader('🏃 Pengingat Jadwal Lari'),
                  const SizedBox(height: 8),
                  _buildCard(
                    children: [
                      SwitchListTile(
                        activeColor: _primaryColor,
                        value: _runEnabled,
                        onChanged: kIsWeb ? null : _toggleRun,
                        title: const Text('Aktifkan Pengingat Lari Harian',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          _runEnabled
                              ? 'Aktif — setiap hari ~${_runHour.toString().padLeft(2, '0')}:${_runMinute.toString().padLeft(2, '0')}'
                              : 'Nonaktif',
                          style: TextStyle(
                            color: _runEnabled
                                ? Colors.orangeAccent
                                : Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        secondary: const Icon(Icons.directions_run,
                            color: Colors.orangeAccent),
                      ),
                      if (_runEnabled) ...[
                        const Divider(color: Colors.white10),
                        ListTile(
                          leading: const Icon(Icons.access_time,
                              color: Colors.white54),
                          title: const Text('Waktu Pengingat',
                              style: TextStyle(color: Colors.white)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_runHour.toString().padLeft(2, '0')}:${_runMinute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right,
                                  color: Colors.white38, size: 18),
                            ],
                          ),
                          onTap: _pickRunTime,
                        ),
                      ],
                      const Divider(color: Colors.white10),
                      _buildTestTile(
                        icon: Icons.send,
                        iconColor: Colors.orangeAccent,
                        buttonColor: Colors.orange.shade700,
                        onTest: () async {
                          final result =
                              await NotificationService.showRunReminder();
                          _handleTestResult(result, 'lari');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Text(
                      '⚠️ Catatan: Waktu notifikasi bersifat perkiraan (inexact) '
                      'karena keterbatasan OS Android demi efisiensi baterai.',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 11, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _handleTestResult(NotifPermissionStatus result, String type) {
    if (!mounted) return;
    switch (result) {
      case NotifPermissionStatus.granted:
        _showSnack('✅ Notifikasi $type berhasil dikirim!');
        setState(() => _permStatus = NotifPermissionStatus.granted);
      case NotifPermissionStatus.permanentlyDenied:
        setState(() => _permStatus = NotifPermissionStatus.permanentlyDenied);
        _showPermanentlyDeniedDialog();
      case NotifPermissionStatus.denied:
        setState(() => _permStatus = NotifPermissionStatus.denied);
        _showSnack('❌ Izin notifikasi ditolak.');
      case NotifPermissionStatus.unsupported:
        _showWebUnsupportedSnack();
    }
  }

  Widget _buildPermissionBanner() {
    if (kIsWeb) {
      return _buildBanner(
        icon: Icons.web,
        color: Colors.deepOrange,
        text: 'Notifikasi lokal tidak didukung di platform Web. Gunakan aplikasi Android atau iOS.',
      );
    }

    switch (_permStatus) {
      case NotifPermissionStatus.granted:
        return _buildBanner(
          icon: Icons.check_circle,
          color: Colors.greenAccent,
          text: '✅ Izin notifikasi sudah diberikan.',
        );
      case NotifPermissionStatus.permanentlyDenied:
        return _buildBanner(
          icon: Icons.block,
          color: Colors.redAccent,
          text: 'Izin notifikasi ditolak permanen. Buka Pengaturan Aplikasi untuk mengaktifkan.',
          action: TextButton(
            onPressed: () => NotificationService.openSettings(),
            child: const Text('Pengaturan',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      default:
        return _buildBanner(
          icon: Icons.notifications_off,
          color: Colors.orange,
          text: 'Izin notifikasi belum diberikan. Tekan tombol Tes untuk meminta izin.',
          action: TextButton(
            onPressed: _askPermission,
            child: const Text('Minta Izin',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
    }
  }

  Widget _buildTestTile({
    required IconData icon,
    required Color iconColor,
    required Color buttonColor,
    required VoidCallback onTest,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 20),
      title: const Text('Kirim Notifikasi Tes',
          style: TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: const Text('Kirim notifikasi langsung sekarang',
          style: TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
        onPressed: kIsWeb ? null : onTest,
        child: const Text('Tes', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildBanner({
    required IconData icon,
    required Color color,
    required String text,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(color: color, fontSize: 12, height: 1.4)),
          ),
          ?action,
        ],
      ),
    );
  }
}
