enum MaintenanceServiceType {
  shop('shop', '店家施工'),
  diy('diy', '自己 DIY');

  const MaintenanceServiceType(this.value, this.label);

  factory MaintenanceServiceType.fromValue(String? value) {
    return MaintenanceServiceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MaintenanceServiceType.shop,
    );
  }

  final String value;
  final String label;
}

enum MaintenanceType {
  general('general', '一般保養'),
  oilChange('oil_change', '機油更換');

  const MaintenanceType(this.value, this.label);

  factory MaintenanceType.fromValue(String? value) {
    return MaintenanceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MaintenanceType.general,
    );
  }

  final String value;
  final String label;
}

class MaintenanceRecord {
  const MaintenanceRecord({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.item,
    required this.maintenanceType,
    required this.servicedAt,
    required this.odometer,
    required this.amount,
    required this.serviceType,
    required this.createdAt,
    this.note,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      item: json['item'] as String,
      maintenanceType: MaintenanceType.fromValue(
        json['maintenance_type'] as String?,
      ),
      servicedAt: DateTime.parse(json['serviced_at'] as String),
      odometer: json['odometer'] as int,
      amount: (json['amount'] as num).toDouble(),
      serviceType: MaintenanceServiceType.fromValue(
        json['service_type'] as String?,
      ),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String userId;
  final String vehicleId;
  final String item;
  final MaintenanceType maintenanceType;
  final DateTime servicedAt;
  final int odometer;
  final double amount;
  final MaintenanceServiceType serviceType;
  final String? note;
  final DateTime createdAt;
}

class NewMaintenanceRecordInput {
  const NewMaintenanceRecordInput({
    required this.vehicleId,
    required this.item,
    required this.maintenanceType,
    required this.servicedAt,
    required this.odometer,
    required this.amount,
    required this.serviceType,
    this.note,
  });

  final String vehicleId;
  final String item;
  final MaintenanceType maintenanceType;
  final DateTime servicedAt;
  final int odometer;
  final double amount;
  final MaintenanceServiceType serviceType;
  final String? note;
}
