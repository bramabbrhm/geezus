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
  // Palette Warna Geezus
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  // State Pelacakan GPS & Peta
  bool _isTracking = false;
  bool _isMapReady = false;
  final List<LatLng> _routePoints = [];
  double _totalDistanceMeters = 0.0;
  StreamSubscription<Position>? _positionSubscription;

  // Koordinat awal default (Jakarta / Posisi Awal)
  LatLng _currentPosition = const LatLng(-6.200000, 106.816666);
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

    // Cek dan Minta Izin GPS
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek Service GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _cardColor,
            content: const Text(
              'Layanan GPS nonaktif. Harap aktifkan GPS untuk tracking.',
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

    // 2. Cek Status Izin Lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin akses lokasi ditolak.'),
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _cardColor,
            content: const Text(
              'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengizinkan.',
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

    // 3. Izin Granted -> Ambil koordinat fisik & Center kamera
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _safeMoveMap(_currentPosition, 16.0);
      }
    } catch (e) {
      debugPrint('Error mendapatkan lokasi awal: $e');
    }
  }

  void _safeMoveMap(LatLng center, double zoom) {
    if (_isMapReady) {
      _mapController.move(center, zoom);
    }
  }

  // Mulai atau Hentikan Tracking Lari
  void _toggleTracking() {
    if (_isTracking) {
      _positionSubscription?.cancel();

      final double runKm = _totalDistanceMeters / 1000;

      if (runKm > 0) {
        // Kirim jarak lari ke GymStore terpusat agar Bonus Damage bertambah!
        GymStore.instance.addRunDistance(runKm);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: _primaryColor,
              content: Text(
                '🏃 Lari Selesai! +${runKm.toStringAsFixed(2)} km (+${(runKm * 25).round()} Speed Damage) dikirim ke Dungeon!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      }

      setState(() {
        _isTracking = false;
      });
    } else {
      setState(() {
        _isTracking = true;
        _routePoints.clear();
        _totalDistanceMeters = 0.0;
        _routePoints.add(_currentPosition);
      });

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          if (!mounted) return;

          LatLng newPoint = LatLng(position.latitude, position.longitude);
          setState(() {
            if (_routePoints.isNotEmpty) {
              final Distance distance = const Distance();
              _totalDistanceMeters += distance.as(
                LengthUnit.Meter,
                _routePoints.last,
                newPoint,
              );
            }
            _routePoints.add(newPoint);
            _currentPosition = newPoint;
          });

          _safeMoveMap(newPoint, 17.0);
        },
        onError: (e) {
          debugPrint('Error GPS tracking stream: $e');
        },
      );
    }
  }

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
            // Panel Ringkasan Stat Lari
            Container(
              padding: const EdgeInsets.all(16),
              color: _cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('JARAK LARI', '${runKm.toStringAsFixed(2)} km', Colors.white),
                  Container(height: 30, width: 1, color: Colors.white24),
                  _buildStatItem('EST. DAMAGE', '+$estimatedRunDamage DMG', Colors.amber),
                  Container(height: 30, width: 1, color: Colors.white24),
                  _buildStatItem('STATUS', _isTracking ? 'RUNNING' : 'STOPPED', _isTracking ? Colors.greenAccent : Colors.redAccent),
                ],
              ),
            ),

            // Tampilan Peta OpenStreetMap
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 16.0,
                      onMapReady: () {
                        setState(() {
                          _isMapReady = true;
                        });
                        _safeMoveMap(_currentPosition, 16.0);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.geezus.app',
                      ),
                      // Jalur Garis Lari (Polyline)
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
                      // Marker Lokasi Terkini
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: _primaryColor, width: 3),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.directions_run_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Tombol Re-center Peta
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      backgroundColor: _cardColor,
                      child: const Icon(Icons.my_location, color: Colors.white),
                      onPressed: () => _safeMoveMap(_currentPosition, 17.0),
                    ),
                  ),
                ],
              ),
            ),

            // Tombol Mulai / Selesai Lari
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
                    backgroundColor: _isTracking ? Colors.redAccent : _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _toggleTracking,
                  icon: Icon(
                    _isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isTracking ? 'STOP TRACKING & SEND DMG' : 'START RUNNING',
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
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}