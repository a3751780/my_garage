class FuelRecord {
  const FuelRecord({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.fueledAt,
    required this.odometer,
    required this.fuelVolume,
    required this.amount,
    required this.fuelType,
    required this.createdAt,
    this.note,
  });

  factory FuelRecord.fromJson(Map<String, dynamic> json) {
    return FuelRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      fueledAt: DateTime.parse(json['fueled_at'] as String),
      odometer: json['odometer'] as int,
      fuelVolume: (json['fuel_volume'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      fuelType: json['fuel_type'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String userId;
  final String vehicleId;
  final DateTime fueledAt;
  final int odometer;
  final double fuelVolume;
  final double amount;
  final String fuelType;
  final String? note;
  final DateTime createdAt;
}

class NewFuelRecordInput {
  const NewFuelRecordInput({
    required this.vehicleId,
    required this.fueledAt,
    required this.odometer,
    required this.fuelVolume,
    required this.amount,
    required this.fuelType,
    this.note,
  });

  final String vehicleId;
  final DateTime fueledAt;
  final int odometer;
  final double fuelVolume;
  final double amount;
  final String fuelType;
  final String? note;
}
