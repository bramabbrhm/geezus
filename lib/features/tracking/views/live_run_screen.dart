<<<<<<< HEAD
import 'package:flutter/material.dart';

class LiveRunScreen extends StatelessWidget {
  const LiveRunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Run Tracking'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          // Map Placeholder Area
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6C5CE7), width: 1),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 60, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Google Maps LBS Live Polyline Area', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          // Realtime Stats
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E2C),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
=======
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

  // Map Controller & Koordinat Default (Jakarta / Monas)
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(-6.175392, 106.827153);

  // Tracking State
  final List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;
  double _totalDistanceMeters = 0.0;
  bool _isMapReady = false;

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

  // Cek Izin & Ambil Lokasi Awal secara Aman
  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Pindahkan kamera hanya jika peta sudah siap dirender
      if (_isMapReady) {
        _safeMoveMap(_currentPosition, 16.0);
      }
    } catch (e) {
      debugPrint('Error mendapatkan lokasi awal: $e');
    }
  }

  // Pindahkan Kamera Peta dengan Safe Guard
  void _safeMoveMap(LatLng center, double zoom) {
    if (_isMapReady) {
      try {
        _mapController.move(center, zoom);
      } catch (e) {
        debugPrint('MapController belum siap dipanggil: $e');
      }
    }
  }

  // Mulai / Hentikan Tracking Lari
  void _toggleTracking() {
    if (_isTracking) {
      _positionSubscription?.cancel();
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
        distanceFilter: 3, // Update tiap berpindah 3 meter
      );

      _positionSubscription =
          Geolocator.getPositionStream(
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
              debugPrint('Error tracking stream: $e');
            },
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'LBS GPS Live Tracking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _cardColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Widget OpenStreetMap Gratis (flutter_map)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.0,
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                });
                _safeMoveMap(_currentPosition, 15.0);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.geezus.app',
              ),
              // PERBAIKAN: Hanya aktif jika ada minimal 2 titik untuk menghindari crash LatLngBounds
              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: List.from(_routePoints),
                      strokeWidth: 5.0,
                      color: _primaryColor,
                    ),
                  ],
                ),
              // Marker Posisi Terkini
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.my_location,
                          color: _primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Overlay Panel Informasi & Kontrol
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
<<<<<<< HEAD
                      _buildStatItem('DISTANCE', '3.45', 'km'),
                      _buildStatItem('STEPS', '4,820', 'steps'),
                      _buildStatItem('PACE', '5\'30"', '/km'),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B894),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('START RUNNING', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
=======
                      _buildStatColumn(
                        'JARAK LARI',
                        '${(_totalDistanceMeters / 1000).toStringAsFixed(2)} km',
                      ),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildStatColumn(
                        'EXP MINGGUAN',
                        '+${(_totalDistanceMeters * 0.1).round()} EXP',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracking
                            ? Colors.redAccent
                            : _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: _toggleTracking,
                      icon: Icon(
                        _isTracking ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isTracking ? 'STOP TRACKING' : 'START RUNNING',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  static Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(unit, style: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 12)),
      ],
    );
  }
}
=======
  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
>>>>>>> 2bc424decba5c876172aaae445851ffce3b4c1ce
