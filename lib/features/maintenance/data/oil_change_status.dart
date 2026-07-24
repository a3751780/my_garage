import 'maintenance_record.dart';

class OilChangeStatus {
  const OilChangeStatus({
    required this.interval,
    this.lastRecord,
    this.drivenMileage = 0,
    this.remainingMileage,
    this.nextChangeMileage,
    this.progress = 0,
  });

  factory OilChangeStatus.fromRecords({
    required List<MaintenanceRecord> records,
    required int currentMileage,
    required int interval,
  }) {
    final lastRecord = findLastOilRecord(records);

    if (lastRecord == null) {
      return OilChangeStatus(
        interval: interval,
        remainingMileage: interval,
      );
    }

    final drivenMileage = currentMileage - lastRecord.odometer;
    final safeDrivenMileage = drivenMileage < 0 ? 0 : drivenMileage;
    final remainingMileage = interval - safeDrivenMileage;

    return OilChangeStatus(
      interval: interval,
      lastRecord: lastRecord,
      drivenMileage: safeDrivenMileage,
      remainingMileage: remainingMileage,
      nextChangeMileage: lastRecord.odometer + interval,
      progress: (safeDrivenMileage / interval).clamp(0.0, 1.0),
    );
  }

  static MaintenanceRecord? findLastOilRecord(
    List<MaintenanceRecord> records,
  ) {
    final oilRecords = records
        .where((record) => record.maintenanceType == MaintenanceType.oilChange)
        .toList()
      ..sort((a, b) => b.odometer.compareTo(a.odometer));

    return oilRecords.isEmpty ? null : oilRecords.first;
  }

  final int interval;
  final MaintenanceRecord? lastRecord;
  final int drivenMileage;
  final int? remainingMileage;
  final int? nextChangeMileage;
  final double progress;

  bool get canEstimate => lastRecord != null && remainingMileage != null;

  bool get isOverdue => canEstimate && remainingMileage! <= 0;
}
