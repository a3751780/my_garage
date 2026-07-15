import 'package:flutter_test/flutter_test.dart';
import 'package:my_garage/features/fuel/data/fuel_analytics.dart';
import 'package:my_garage/features/fuel/data/fuel_record.dart';

void main() {
  group('FuelAnalytics', () {
    test('estimates next refuel mileage from latest fuel efficiency', () {
      final analytics = FuelAnalytics.fromRecords(
        [
          _fuelRecord(
            id: '1',
            odometer: 1000,
            fuelVolume: 5,
            amount: 150,
          ),
          _fuelRecord(
            id: '2',
            odometer: 1200,
            fuelVolume: 5,
            amount: 160,
          ),
          _fuelRecord(
            id: '3',
            odometer: 1400,
            fuelVolume: 6,
            amount: 190,
          ),
        ],
        currentMileage: 1500,
      );

      expect(analytics.canEstimateRefuel, isTrue);
      expect(analytics.estimatedTankVolume, 6);
      expect(analytics.latestFuelEfficiency, closeTo(33.333, 0.001));
      expect(analytics.estimatedFullTankRange, closeTo(200, 0.001));
      expect(analytics.drivenSinceLastFuel, 100);
      expect(analytics.remainingMileageToRefuel, closeTo(100, 0.001));
      expect(analytics.nextRefuelMileage, 1600);
      expect(analytics.refuelProgress, closeTo(0.5, 0.001));
    });

    test('does not estimate refuel mileage with only one record', () {
      final analytics = FuelAnalytics.fromRecords(
        [
          _fuelRecord(
            id: '1',
            odometer: 1000,
            fuelVolume: 5,
            amount: 150,
          ),
        ],
        currentMileage: 1050,
      );

      expect(analytics.canEstimateRefuel, isFalse);
      expect(analytics.remainingMileageToRefuel, isNull);
      expect(analytics.nextRefuelMileage, isNull);
    });
  });
}

FuelRecord _fuelRecord({
  required String id,
  required int odometer,
  required double fuelVolume,
  required double amount,
}) {
  return FuelRecord(
    id: id,
    userId: 'user-id',
    vehicleId: 'vehicle-id',
    fueledAt: DateTime(2026, 7, 15),
    odometer: odometer,
    fuelVolume: fuelVolume,
    amount: amount,
    fuelType: '95',
    createdAt: DateTime(2026, 7, 15),
  );
}
