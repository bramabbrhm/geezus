import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LiveRunScreen extends StatefulWidget {
  const LiveRunScreen({super.key});

  @override
  State<LiveRunScreen> createState() => _LiveRunScreenState();
}

class _LiveRunScreenState extends State<LiveRunScreen> {
  // Map Controller & Location
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentPosition;
  final List<LatLng> _routePoints = [];

  // Stat Lari
  bool _isTracking = false;
  bool _isPaused = false;
  double _totalDistanceInMeters = 0.0;
  int _secondsElapsed = 0;
  Timer? _timer;

  // Palette Warna Projek Geezus
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _cardColor = Color(0xFF1E1E2C);
  static const Color _bgColor = Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // Defensive programming: Cek & minta izin GPS
  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layanan GPS/Lokasi belum aktif.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin akses lokasi ditolak.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi ditolak permanen. Buka pengaturan HP.',
              ),
            ),
          );
        }
        return;
      }

      Position initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(initialPos.latitude, initialPos.longitude);
      });

      _mapController.move(_currentPosition!, 17.0);
    } catch (e) {
      debugPrint('Error inisialisasi lokasi: $e');
    }
  }

  void _startRun() {
    setState(() {
      _isTracking = true;
      _isPaused = false;
      _totalDistanceInMeters = 0.0;
      _secondsElapsed = 0;
      _routePoints.clear();
    });

    _startTimer();
    _listenToLocationUpdates();
  }

  void _pauseRun() {
    setState(() {
      _isPaused = true;
    });
    _timer?.cancel();
    _positionStream?.pause();
  }

  void _resumeRun() {
    setState(() {
      _isPaused = false;
    });
    _startTimer();
    _positionStream?.resume();
  }

  void _stopRun() {
    _timer?.cancel();
    _positionStream?.cancel();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text(
          'Lari Selesai! 🏃‍♂️',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jarak Total: ${(_totalDistanceInMeters / 1000).toStringAsFixed(2)} km',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Waktu: ${_formatDuration(_secondsElapsed)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Pace Rata-rata: ${_calculatePace()}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isTracking = false;
                _isPaused = false;
              });
            },
            child: const Text(
              'Simpan & Tutup',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _listenToLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3, // Update lokasi tiap bergerak 3 meter
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (_isPaused) return;

            LatLng newPoint = LatLng(position.latitude, position.longitude);

            setState(() {
              if (_routePoints.isNotEmpty) {
                LatLng lastPoint = _routePoints.last;
                double distance = Geolocator.distanceBetween(
                  lastPoint.latitude,
                  lastPoint.longitude,
                  newPoint.latitude,
                  newPoint.longitude,
                );
                _totalDistanceInMeters += distance;
              }

              _routePoints.add(newPoint);
              _currentPosition = newPoint;
            });

            _mapController.move(newPoint, 17.0);
          },
          onError: (error) {
            debugPrint('Error streaming lokasi: $error');
          },
        );
  }

  String _formatDuration(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    final int hrs = mins ~/ 60;
    if (hrs > 0) {
      return '${hrs.toString().padLeft(2, '0')}:${(mins % 60).toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _calculatePace() {
    if (_totalDistanceInMeters == 0) return "0'00\"";
    double km = _totalDistanceInMeters / 1000;
    double minutes = _secondsElapsed / 60;
    double paceDecimal = minutes / km;
    int paceMin = paceDecimal.toInt();
    int paceSec = ((paceDecimal - paceMin) * 60).round();
    return "$paceMin'${paceSec.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
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
      body: Stack(
        children: [
          // OpenStreetMap Container
          _currentPosition == null
              ? const Center(
                  child: CircularProgressIndicator(color: _primaryColor),
                )
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition!,
                    initialZoom: 17.0,
                  ),
                  children: [
                    // Layer Peta OpenStreetMap (Gratis & No Key Required)
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.geezus.app',
                    ),

                    // Garis Rute Lari
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5.0,
                          color: _primaryColor,
                        ),
                      ],
                    ),

                    // Marker Titik Awal & Posisi Sekarang
                    MarkerLayer(
                      markers: [
                        if (_routePoints.isNotEmpty)
                          Marker(
                            point: _routePoints.first,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 36,
                            ),
                          ),
                        Marker(
                          point: _currentPosition!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.my_location,
                            color: _primaryColor,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

          // Dashboard Statistik Atas
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: _cardColor.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'JARAK',
                      '${(_totalDistanceInMeters / 1000).toStringAsFixed(2)}',
                      'KM',
                    ),
                    _buildStatColumn(
                      'DURASI',
                      _formatDuration(_secondsElapsed),
                      '',
                    ),
                    _buildStatColumn('PACE', _calculatePace(), '/KM'),
                  ],
                ),
              ),
            ),
          ),

          // Tombol Kontrol Bawah
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildControlButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, String unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(
                  color: _primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    if (!_isTracking) {
      return SizedBox(
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: _startRun,
          child: const Text(
            'MULAI LARI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton.large(
          heroTag: 'pause_resume',
          backgroundColor: Colors.amber,
          onPressed: _isPaused ? _resumeRun : _pauseRun,
          child: Icon(
            _isPaused ? Icons.play_arrow : Icons.pause,
            color: Colors.black,
            size: 36,
          ),
        ),
        FloatingActionButton.large(
          heroTag: 'stop',
          backgroundColor: Colors.redAccent,
          onPressed: _stopRun,
          child: const Icon(Icons.stop, color: Colors.white, size: 36),
        ),
      ],
    );
  }
}