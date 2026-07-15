class Vehicle {
  const Vehicle({
    required this.id,
    required this.userId,
    required this.model,
    required this.year,
    required this.initialMileage,
    required this.currentMileage,
    required this.acquisitionCost,
    required this.createdAt,
    this.coverImagePath,
    this.coverImageUrl,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json, {String? coverImageUrl}) {
    return Vehicle(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      initialMileage: json['initial_mileage'] as int? ?? 0,
      currentMileage: json['current_mileage'] as int,
      acquisitionCost: (json['acquisition_cost'] as num).toDouble(),
      coverImagePath: json['cover_image_path'] as String?,
      coverImageUrl: coverImageUrl,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String userId;
  final String model;
  final int year;
  final int initialMileage;
  final int currentMileage;
  final double acquisitionCost;
  final String? coverImagePath;
  final String? coverImageUrl;
  final DateTime createdAt;

  Vehicle copyWith({
    String? id,
    String? userId,
    String? model,
    int? year,
    int? initialMileage,
    int? currentMileage,
    double? acquisitionCost,
    String? coverImagePath,
    String? coverImageUrl,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      model: model ?? this.model,
      year: year ?? this.year,
      initialMileage: initialMileage ?? this.initialMileage,
      currentMileage: currentMileage ?? this.currentMileage,
      acquisitionCost: acquisitionCost ?? this.acquisitionCost,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NewVehicleInput {
  const NewVehicleInput({
    required this.model,
    required this.year,
    required this.initialMileage,
    required this.currentMileage,
    required this.acquisitionCost,
    this.coverImageBytes,
    this.coverImageFileName,
  });

  final String model;
  final int year;
  final int initialMileage;
  final int currentMileage;
  final double acquisitionCost;
  final List<int>? coverImageBytes;
  final String? coverImageFileName;
}
