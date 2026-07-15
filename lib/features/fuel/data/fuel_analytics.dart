import 'fuel_record.dart';

class FuelAnalytics {
  const FuelAnalytics({
    required this.recordCount,
    required this.monthlyFuelCost,
    this.latestFuelEfficiency,
    this.averageFuelEfficiency,
    this.costPerKilometer,
    this.estimatedTankVolume,
    this.lastFueledMileage,
    this.estimatedFullTankRange,
    this.drivenSinceLastFuel,
    this.remainingMileageToRefuel,
    this.nextRefuelMileage,
    this.refuelProgress,
  });

  factory FuelAnalytics.fromRecords(
    List<FuelRecord> records, {
    DateTime? now,
    int? currentMileage,
  }) {
    final today = now ?? DateTime.now();
    final sortedRecords = [...records]
      ..sort((a, b) => a.odometer.compareTo(b.odometer));
    final monthlyFuelCost = records
        .where(
          (record) =>
              record.fueledAt.year == today.year &&
              record.fueledAt.month == today.month,
        )
        .fold<double>(0, (total, record) => total + record.amount);

    var totalDistance = 0;
    var totalFuelVolume = 0.0;
    var totalFuelCost = 0.0;
    double? latestFuelEfficiency;
    double? estimatedTankVolume;

    for (var index = 1; index < sortedRecords.length; index++) {
      final previous = sortedRecords[index - 1];
      final current = sortedRecords[index];
      final distance = current.odometer - previous.odometer;

      if (distance <= 0 || current.fuelVolume <= 0) {
        continue;
      }

      final efficiency = distance / current.fuelVolume;
      latestFuelEfficiency = efficiency;
      totalDistance += distance;
      totalFuelVolume += current.fuelVolume;
      totalFuelCost += current.amount;
    }

    for (final record in records) {
      if (record.fuelVolume <= 0) {
        continue;
      }

      estimatedTankVolume = estimatedTankVolume == null
          ? record.fuelVolume
          : record.fuelVolume > estimatedTankVolume
              ? record.fuelVolume
              : estimatedTankVolume;
    }

    final averageFuelEfficiency =
        totalFuelVolume == 0 ? null : totalDistance / totalFuelVolume;
    final efficiencyForRange = latestFuelEfficiency ?? averageFuelEfficiency;
    final latestRecord = sortedRecords.isEmpty ? null : sortedRecords.last;
    double? estimatedFullTankRange;
    int? drivenSinceLastFuel;
    double? remainingMileageToRefuel;
    int? nextRefuelMileage;
    double? refuelProgress;

    if (currentMileage != null &&
        latestRecord != null &&
        estimatedTankVolume != null &&
        efficiencyForRange != null &&
        estimatedTankVolume > 0 &&
        efficiencyForRange > 0) {
      estimatedFullTankRange = estimatedTankVolume * efficiencyForRange;
      drivenSinceLastFuel = (currentMileage - latestRecord.odometer).clamp(
        0,
        1 << 31,
      );
      remainingMileageToRefuel = estimatedFullTankRange - drivenSinceLastFuel;
      nextRefuelMileage =
          latestRecord.odometer + estimatedFullTankRange.round();
      refuelProgress = (drivenSinceLastFuel / estimatedFullTankRange).clamp(
        0.0,
        1.0,
      );
    }

    return FuelAnalytics(
      recordCount: records.length,
      latestFuelEfficiency: latestFuelEfficiency,
      averageFuelEfficiency: averageFuelEfficiency,
      costPerKilometer:
          totalDistance == 0 ? null : totalFuelCost / totalDistance,
      monthlyFuelCost: monthlyFuelCost,
      estimatedTankVolume: estimatedTankVolume,
      lastFueledMileage: latestRecord?.odometer,
      estimatedFullTankRange: estimatedFullTankRange,
      drivenSinceLastFuel: drivenSinceLastFuel,
      remainingMileageToRefuel: remainingMileageToRefuel,
      nextRefuelMileage: nextRefuelMileage,
      refuelProgress: refuelProgress,
    );
  }

  final int recordCount;
  final double? latestFuelEfficiency;
  final double? averageFuelEfficiency;
  final double? costPerKilometer;
  final double monthlyFuelCost;
  final double? estimatedTankVolume;
  final int? lastFueledMileage;
  final double? estimatedFullTankRange;
  final int? drivenSinceLastFuel;
  final double? remainingMileageToRefuel;
  final int? nextRefuelMileage;
  final double? refuelProgress;

  bool get hasEnoughRecordsForEfficiency => recordCount >= 2;

  bool get canEstimateRefuel =>
      estimatedTankVolume != null &&
      lastFueledMileage != null &&
      estimatedFullTankRange != null &&
      drivenSinceLastFuel != null &&
      remainingMileageToRefuel != null &&
      nextRefuelMileage != null &&
      refuelProgress != null;
}
