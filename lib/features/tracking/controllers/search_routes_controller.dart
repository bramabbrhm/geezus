import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_model.dart';

/// Controller untuk fitur pencarian dan filter rute lari dari Supabase.
/// Jika tabel 'routes' belum ada di Supabase atau tidak dapat diakses,
/// controller secara otomatis menampilkan data rute lokal sebagai fallback.
class SearchRoutesController extends ChangeNotifier {
  final SupabaseClient _supabase;

  SearchRoutesController({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  List<RouteModel> _routes = [];
  List<RouteModel> _filteredRoutes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _usingLocalFallback = false;
  String _searchQuery = '';
  String _selectedDifficulty = 'All';
  RouteModel? _selectedRoute;

  // Getters
  List<RouteModel> get routes => _filteredRoutes;
  List<RouteModel> get allRoutes => _routes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedDifficulty => _selectedDifficulty;
  RouteModel? get selectedRoute => _selectedRoute;
  bool get hasError => _errorMessage != null && !_usingLocalFallback;
  bool get isEmpty => !_isLoading && _filteredRoutes.isEmpty;
  bool get usingLocalFallback => _usingLocalFallback;

  // ── Local fallback data ───────────────────────────────────────────────────
  // Ditampilkan ketika tabel 'routes' di Supabase belum dibuat atau tidak
  // dapat diakses (koneksi putus, RLS, dsb).
  static final List<RouteModel> _localFallbackRoutes = [
    const RouteModel(
      id: 'local_1',
      name: 'Rute Kampus UGM',
      activityType: 'running',
      distanceKm: 5.2,
      difficulty: 'Easy',
      description: 'Rute lari ringan di area kampus Universitas Gadjah Mada.',
      startLat: -7.7700,
      startLng: 110.3775,
    ),
    const RouteModel(
      id: 'local_2',
      name: 'Jalan Malioboro Loop',
      activityType: 'running',
      distanceKm: 7.5,
      difficulty: 'Medium',
      description:
          'Rute perkotaan melewati kawasan wisata Malioboro dan sekitarnya.',
      startLat: -7.7956,
      startLng: 110.3695,
    ),
    const RouteModel(
      id: 'local_3',
      name: 'Jalur Merapi Trail',
      activityType: 'trail_run',
      distanceKm: 10.0,
      difficulty: 'Hard',
      description: 'Trek gunung melewati jalur bawah Gunung Merapi.',
      startLat: -7.6414,
      startLng: 110.4458,
    ),
    const RouteModel(
      id: 'local_4',
      name: 'Promenade Pantai Parangtritis',
      activityType: 'running',
      distanceKm: 4.0,
      difficulty: 'Easy',
      description: 'Lari santai di bibir pantai Parangtritis saat pagi hari.',
      startLat: -8.0251,
      startLng: 110.3327,
    ),
    const RouteModel(
      id: 'local_5',
      name: 'Rute Kota Tua Yogyakarta',
      activityType: 'running',
      distanceKm: 6.3,
      difficulty: 'Medium',
      description: 'Melewati jalan-jalan bersejarah di pusat kota Yogyakarta.',
      startLat: -7.8013,
      startLng: 110.3645,
    ),
  ];

  // ── Supabase fetch ────────────────────────────────────────────────────────

  /// Mengambil daftar rute dari tabel 'routes' di Supabase.
  /// Jika gagal, otomatis beralih ke data rute lokal sebagai fallback.
  Future<void> fetchRoutes() async {
    _isLoading = true;
    _errorMessage = null;
    _usingLocalFallback = false;
    notifyListeners();

    try {
      final response = await _supabase
          .from('routes')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8));

      final List<dynamic> data = response as List<dynamic>;
      _routes = data
          .map((item) => RouteModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (_routes.isEmpty) {
        // Tabel ada tapi kosong — tampilkan fallback
        _useFallback();
      } else {
        _applyFilters();
      }
    } catch (e) {
      debugPrint('SearchRoutesController fetchRoutes error: $e');
      // Sembunyikan detail teknis Supabase, tampilkan fallback
      _useFallback();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _useFallback() {
    _usingLocalFallback = true;
    _routes = List.from(_localFallbackRoutes);
    _applyFilters();
    debugPrint('SearchRoutesController: using local fallback routes');
  }

  // ── Filter & search ───────────────────────────────────────────────────────

  void onSearchQueryChanged(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void onDifficultyFilterChanged(String difficulty) {
    _selectedDifficulty = difficulty;
    _applyFilters();
    notifyListeners();
  }

  void selectRoute(RouteModel? route) {
    _selectedRoute = route;
    notifyListeners();
  }

  void _applyFilters() {
    _filteredRoutes = _routes.where((route) {
      final queryLower = _searchQuery.toLowerCase().trim();
      final matchesQuery = queryLower.isEmpty ||
          route.name.toLowerCase().contains(queryLower) ||
          (route.description?.toLowerCase().contains(queryLower) ?? false);

      final matchesDifficulty = _selectedDifficulty == 'All' ||
          route.difficulty.toLowerCase() ==
              _selectedDifficulty.toLowerCase();

      return matchesQuery && matchesDifficulty;
    }).toList();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedDifficulty = 'All';
    _applyFilters();
    notifyListeners();
  }
}
