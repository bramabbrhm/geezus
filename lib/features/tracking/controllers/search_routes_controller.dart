import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_model.dart';

/// Controller untuk fitur pencarian dan filter rute lari dari Supabase
class SearchRoutesController extends ChangeNotifier {
  final SupabaseClient _supabase;

  SearchRoutesController({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  List<RouteModel> _routes = [];
  List<RouteModel> _filteredRoutes = [];
  bool _isLoading = false;
  String? _errorMessage;
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
  bool get hasError => _errorMessage != null;
  bool get isEmpty => !_isLoading && _filteredRoutes.isEmpty;

  /// Mengambil daftar seluruh rute dari tabel 'routes' di Supabase
  Future<void> fetchRoutes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('routes')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      _routes = data
          .map((item) => RouteModel.fromJson(item as Map<String, dynamic>))
          .toList();

      _applyFilters();
    } catch (e) {
      _errorMessage = 'Gagal memuat rute dari Supabase: $e';
      debugPrint('SearchRoutesController error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update query pencarian lokal (nama rute atau deskripsi)
  void onSearchQueryChanged(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Update filter berdasarkan tingkat kesulitan ('All', 'Easy', 'Medium', 'Hard')
  void onDifficultyFilterChanged(String difficulty) {
    _selectedDifficulty = difficulty;
    _applyFilters();
    notifyListeners();
  }

  /// Memilih satu rute tertentu untuk dijadikan target tracking atau preview di peta
  void selectRoute(RouteModel? route) {
    _selectedRoute = route;
    notifyListeners();
  }

  /// Menjalankan query pencarian langsung ke database Supabase (server-side search)
  Future<void> searchRoutesDirectly(String query) async {
    _isLoading = true;
    _errorMessage = null;
    _searchQuery = query;
    notifyListeners();

    try {
      var queryBuilder = _supabase.from('routes').select();

      if (query.trim().isNotEmpty) {
        queryBuilder = queryBuilder.ilike('name', '%$query%');
      }

      if (_selectedDifficulty != 'All') {
        queryBuilder = queryBuilder.eq('difficulty', _selectedDifficulty);
      }

      final response = await queryBuilder.order('distance_km', ascending: true);
      final List<dynamic> data = response as List<dynamic>;

      _filteredRoutes = data
          .map((item) => RouteModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = 'Pencarian langsung ke Supabase gagal: $e';
      debugPrint('searchRoutesDirectly error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logika filter lokal (client-side) dari data rute yang sudah diunduh
  void _applyFilters() {
    _filteredRoutes = _routes.where((route) {
      final queryLower = _searchQuery.toLowerCase().trim();
      final matchesQuery = queryLower.isEmpty ||
          route.name.toLowerCase().contains(queryLower) ||
          (route.description?.toLowerCase().contains(queryLower) ?? false);

      final matchesDifficulty = _selectedDifficulty == 'All' ||
          route.difficulty.toLowerCase() == _selectedDifficulty.toLowerCase();

      return matchesQuery && matchesDifficulty;
    }).toList();
  }

  /// Reset semua filter pencarian
  void resetFilters() {
    _searchQuery = '';
    _selectedDifficulty = 'All';
    _applyFilters();
    notifyListeners();
  }
}

