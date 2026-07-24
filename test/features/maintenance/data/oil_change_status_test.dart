import 'package:flutter_test/flutter_test.dart';
import 'package:my_garage/features/maintenance/data/maintenance_record.dart';
import 'package:my_garage/features/maintenance/data/oil_change_status.dart';

void main() {
  group('OilChangeStatus', () {
    test('uses latest oil change record to calculate remaining mileage', () {
      final status = OilChangeStatus.fromRecords(
        records: [
          _maintenanceRecord(
            id: 'general',
            item: '輪胎',
            maintenanceType: MaintenanceType.general,
            odometer: 1800,
          ),
          _maintenanceRecord(
            id: 'old-oil',
            item: '機油',
            maintenanceType: MaintenanceType.oilChange,
            odometer: 1000,
          ),
          _maintenanceRecord(
            id: 'new-oil',
            item: '換油',
            maintenanceType: MaintenanceType.oilChange,
            odometer: 2100,
          ),
        ],
        currentMileage: 2500,
        interval: 1000,
      );

      expect(status.lastRecord?.id, 'new-oil');
      expect(status.drivenMileage, 400);
      expect(status.remainingMileage, 600);
      expect(status.nextChangeMileage, 3100);
      expect(status.progress, 0.4);
      expect(status.isOverdue, isFalse);
    });

    test('marks oil change as overdue', () {
      final status = OilChangeStatus.fromRecords(
        records: [
          _maintenanceRecord(
            id: 'oil',
            item: '機油',
            maintenanceType: MaintenanceType.oilChange,
            odometer: 1000,
          ),
        ],
        currentMileage: 2200,
        interval: 1000,
      );

      expect(status.remainingMileage, -200);
      expect(status.isOverdue, isTrue);
    });
  });
}

MaintenanceRecord _maintenanceRecord({
  required String id,
  required String item,
  required MaintenanceType maintenanceType,
  required int odometer,
}) {
  return MaintenanceRecord(
    id: id,
    userId: 'user-id',
    vehicleId: 'vehicle-id',
    item: item,
    maintenanceType: maintenanceType,
    servicedAt: DateTime(2026, 7, 15),
    odometer: odometer,
    amount: 100,
    serviceType: MaintenanceServiceType.shop,
    createdAt: DateTime(2026, 7, 15),
  );
}
