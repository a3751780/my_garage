class MaintenanceRecord {
  const MaintenanceRecord({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.item,
    required this.servicedAt,
    required this.odometer,
    required this.amount,
    required this.createdAt,
    this.note,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      item: json['item'] as String,
      servicedAt: DateTime.parse(json['serviced_at'] as String),
      odometer: json['odometer'] as int,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String userId;
  final String vehicleId;
  final String item;
  final DateTime servicedAt;
  final int odometer;
  final double amount;
  final String? note;
  final DateTime createdAt;
}

class NewMaintenanceRecordInput {
  const NewMaintenanceRecordInput({
    required this.vehicleId,
    required this.item,
    required this.servicedAt,
    required this.odometer,
    required this.amount,
    this.note,
  });

  final String vehicleId;
  final String item;
  final DateTime servicedAt;
  final int odometer;
  final double amount;
  final String? note;
}
