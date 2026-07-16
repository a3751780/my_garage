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
      expect(analytics.estimatedTankVolume, closeTo(5.333, 0.001));
      expect(analytics.latestFuelEfficiency, closeTo(33.333, 0.001));
      expect(analytics.estimatedFullTankRange, closeTo(177.777, 0.001));
      expect(analytics.drivenSinceLastFuel, 100);
      expect(analytics.remainingMileageToRefuel, closeTo(77.777, 0.001));
      expect(analytics.nextRefuelMileage, 1578);
      expect(analytics.refuelProgress, closeTo(0.562, 0.001));
    });

    test('excludes small top-up fuel volumes from tank volume estimate', () {
      final analytics = FuelAnalytics.fromRecords(
        [
          _fuelRecord(
            id: '1',
            odometer: 1000,
            fuelVolume: 6,
            amount: 180,
          ),
          _fuelRecord(
            id: '2',
            odometer: 1020,
            fuelVolume: 1,
            amount: 30,
          ),
          _fuelRecord(
            id: '3',
            odometer: 1200,
            fuelVolume: 5,
            amount: 160,
          ),
        ],
        currentMileage: 1250,
      );

      expect(analytics.estimatedTankVolume, closeTo(5.5, 0.001));
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

    test('builds monthly report summaries and trip points', () {
      final report = FuelAnalyticsReport.fromRecords(
        [
          _fuelRecord(
            id: '1',
            odometer: 1000,
            fuelVolume: 5,
            amount: 150,
            fueledAt: DateTime(2026, 1, 10),
          ),
          _fuelRecord(
            id: '2',
            odometer: 1200,
            fuelVolume: 5,
            amount: 160,
            fueledAt: DateTime(2026, 2, 10),
          ),
          _fuelRecord(
            id: '3',
            odometer: 1420,
            fuelVolume: 5.5,
            amount: 180,
            fueledAt: DateTime(2026, 2, 25),
          ),
        ],
      );

      expect(report.monthlySummaries, hasLength(2));
      expect(report.monthlySummaries[0].monthLabel, '1月');
      expect(report.monthlySummaries[0].fuelCost, 150);
      expect(report.monthlySummaries[0].averageEfficiency, isNull);
      expect(report.monthlySummaries[1].fuelCost, 340);
      expect(report.monthlySummaries[1].distance, 420);
      expect(report.monthlySummaries[1].fuelVolume, 10.5);
      expect(report.monthlySummaries[1].averageEfficiency, 40);
      expect(report.tripPoints, hasLength(2));
      expect(report.tripPoints.first.distance, 200);
      expect(report.tripPoints.first.efficiency, 40);
    });
  });
}

FuelRecord _fuelRecord({
  required String id,
  required int odometer,
  required double fuelVolume,
  required double amount,
  DateTime? fueledAt,
}) {
  return FuelRecord(
    id: id,
    userId: 'user-id',
    vehicleId: 'vehicle-id',
    fueledAt: fueledAt ?? DateTime(2026, 7, 15),
    odometer: odometer,
    fuelVolume: fuelVolume,
    amount: amount,
    fuelType: '95',
    createdAt: DateTime(2026, 7, 15),
  );
}
