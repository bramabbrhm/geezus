import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/gym_store.dart';

class LiveRunScreen extends StatefulWidget {
  const LiveRunScreen({super.key});

  @override
  State<LiveRunScreen> createState() => _LiveRunScreenState();
}

class _LiveRunScreenState extends State<LiveRunScreen> {
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  // Tracking state
  bool _isTracking = false;
  bool _isMapReady = false;
  final List<LatLng> _routePoints = [];
  double _totalDistanceMeters = 0.0;
  StreamSubscription<Position>? _positionSubscription;

  // Duration timer
  int _elapsedSeconds = 0;
  Timer? _durationTimer;

  // Default position (Jakarta) — will be replaced once GPS returns real coords
  LatLng _currentPosition = const LatLng(-6.200000, 106.816666);
  bool _hasRealPosition = false;
  final MapController _mapController = MapController();

  // Permission / GPS state messaging
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    // Load GymStore data from SQLite if not yet loaded
    if (!GymStore.instance.isLoaded) {
      GymStore.instance.loadFromDatabase();
    }
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ── Permission & GPS ──────────────────────────────────────────────────────

  Future<void> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _statusMessage = 'GPS nonaktif. Aktifkan GPS untuk tracking.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _cardColor,
            content: const Text(
              'Layanan GPS nonaktif. Aktifkan GPS untuk tracking.',
              style: TextStyle(color: Colors.white),
            ),
            action: SnackBarAction(
              label: 'Buka GPS',
              textColor: _primaryColor,
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _statusMessage = 'Izin lokasi ditolak.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin akses lokasi ditolak.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _statusMessage = 'Izin lokasi ditolak permanen.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _cardColor,
            content: const Text(
              'Izin lokasi ditolak permanen. Buka pengaturan untuk mengizinkan.',
              style: TextStyle(color: Colors.white),
            ),
            action: SnackBarAction(
              label: 'Pengaturan',
              textColor: _primaryColor,
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    // Permission granted — get current position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _hasRealPosition = true;
          _statusMessage = null;
        });
        _safeMoveMap(_currentPosition, 16.0);
      }
    } catch (e) {
      debugPrint('Error getting initial location: $e');
    }
  }

  void _safeMoveMap(LatLng center, double zoom) {
    if (_isMapReady) {
      try {
        _mapController.move(center, zoom);
      } catch (_) {}
    }
  }

  // ── Tracking control ──────────────────────────────────────────────────────

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _routePoints.clear();
      _totalDistanceMeters = 0.0;
      _elapsedSeconds = 0;
      _routePoints.add(_currentPosition);
    });

    // Start duration timer
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3, // only update when moved ≥3 m (reduces GPS jumping)
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (!mounted) return;

        final newPoint = LatLng(position.latitude, position.longitude);
        setState(() {
          if (_routePoints.isNotEmpty) {
            final double addedMeters = const Distance().as(
              LengthUnit.Meter,
              _routePoints.last,
              newPoint,
            );
            // Guard against GPS jumping: ignore jumps > 100m in a single update
            if (addedMeters < 100) {
              _totalDistanceMeters += addedMeters;
            }
          }
          _routePoints.add(newPoint);
          _currentPosition = newPoint;
          _hasRealPosition = true;
        });

        _safeMoveMap(newPoint, 17.0);
      },
      onError: (e) {
        debugPrint('GPS stream error: $e');
      },
    );
  }

  Future<void> _stopTracking() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _durationTimer?.cancel();
    _durationTimer = null;

    final double runKm = _totalDistanceMeters / 1000;

    if (runKm > 0.01) {
      // Persist to GymStore (in-memory + SQLite)
      GymStore.instance.addRunDistance(runKm);
      final int bossDmg = (runKm * 25).round();
      final int calories = (runKm * 65).round(); // ~65 kcal per km

      await GymStore.instance.insertRunRecord(
        distanceKm: runKm,
        durationSeconds: _elapsedSeconds,
        estimatedCalories: calories,
        bossDamage: bossDmg,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _primaryColor,
            duration: const Duration(seconds: 4),
            content: Text(
              '🏃 Lari Selesai! '
              '+${runKm.toStringAsFixed(2)} km '
              '(+$bossDmg Speed DMG, +$calories kcal) '
              'tersimpan ke Dungeon!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } else if (mounted && runKm > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jarak terlalu pendek untuk dicatat (<10m).'),
        ),
      );
    }

    if (mounted) {
      setState(() => _isTracking = false);
    }
  }

  void _toggleTracking() {
    if (_isTracking) {
      _stopTracking();
    } else {
      _startTracking();
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double runKm = _totalDistanceMeters / 1000;
    final int estimatedRunDamage = (runKm * 25).round();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Live Run Tracking',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _cardColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status message (permission denied / GPS off)
            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.orange.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Real-time stats panel
            Container(
              padding: const EdgeInsets.all(14),
              color: _cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'JARAK', '${runKm.toStringAsFixed(2)} km', Colors.white),
                  _buildDivider(),
                  _buildStatItem(
                    'WAKTU', _formatDuration(_elapsedSeconds), Colors.cyanAccent),
                  _buildDivider(),
                  _buildStatItem(
                    'EST. DMG', '+$estimatedRunDamage', Colors.amber),
                  _buildDivider(),
                  _buildStatItem(
                    'STATUS',
                    _isTracking ? 'RUNNING' : 'STOPPED',
                    _isTracking ? Colors.greenAccent : Colors.redAccent),
                ],
              ),
            ),

            // Map
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 15.0,
                      onMapReady: () {
                        setState(() => _isMapReady = true);
                        _safeMoveMap(_currentPosition, 15.0);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.geezus.app',
                      ),
                      if (_routePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 5.0,
                              color: _primaryColor,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                                border: Border.all(color: _primaryColor, width: 3),
                              ),
                              child: const Icon(
                                Icons.directions_run_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Not-real-position warning
                  if (!_hasRealPosition)
                    Positioned(
                      top: 10,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⚠️ Posisi default (Jakarta) — GPS belum mendapat fix lokasi nyata',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  // Re-center button
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'recenter',
                      backgroundColor: _cardColor,
                      child: const Icon(Icons.my_location, color: Colors.white),
                      onPressed: () => _safeMoveMap(_currentPosition, 17.0),
                    ),
                  ),
                ],
              ),
            ),

            // Start / Stop button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: _cardColor,
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isTracking ? Colors.redAccent : _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _toggleTracking,
                  icon: Icon(
                    _isTracking
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isTracking
                        ? 'STOP & SIMPAN HASIL'
                        : 'MULAI TRACKING',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
              color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 3),
        Text(
          val,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDivider() =>
      Container(height: 28, width: 1, color: Colors.white12);
}
