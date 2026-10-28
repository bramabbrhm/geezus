class RouteModel {
  final String id;
  final String name;
  final String activityType;
  final double distanceKm;
  final String difficulty;
  final String? description;
  final double startLat;
  final double startLng;
  final DateTime? createdAt;

  const RouteModel({
    required this.id,
    required this.name,
    this.activityType = 'running',
    required this.distanceKm,
    required this.difficulty,
    this.description,
    required this.startLat,
    required this.startLng,
    this.createdAt,
  });

  /// Factory untuk memetakan data JSON/Map dari Supabase ke instance RouteModel
  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      activityType: json['activity_type']?.toString() ?? 'running',
      distanceKm: (json['distance_km'] is num)
          ? (json['distance_km'] as num).toDouble()
          : double.tryParse(json['distance_km']?.toString() ?? '0') ?? 0.0,
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      description: json['description']?.toString(),
      startLat: (json['start_lat'] is num)
          ? (json['start_lat'] as num).toDouble()
          : double.tryParse(json['start_lat']?.toString() ?? '0') ?? 0.0,
      startLng: (json['start_lng'] is num)
          ? (json['start_lng'] as num).toDouble()
          : double.tryParse(json['start_lng']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Konversi RouteModel kembali ke Map untuk insert/update ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'activity_type': activityType,
      'distance_km': distanceKm,
      'difficulty': difficulty,
      'description': description,
      'start_lat': startLat,
      'start_lng': startLng,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'RouteModel(id: $id, name: $name, distanceKm: $distanceKm km, difficulty: $difficulty)';
  }
}

