import 'fuel_record.dart';

class MonthlyFuelSummary {
  const MonthlyFuelSummary({
    required this.year,
    required this.month,
    required this.fuelCost,
    required this.distance,
    required this.fuelVolume,
  });

  final int year;
  final int month;
  final double fuelCost;
  final int distance;
  final double fuelVolume;

  double? get averageEfficiency {
    if (distance <= 0 || fuelVolume <= 0) {
      return null;
    }

    return distance / fuelVolume;
  }

  String get monthLabel => '$month月';
}

class FuelEfficiencyTripPoint {
  const FuelEfficiencyTripPoint({
    required this.year,
    required this.month,
    required this.distance,
    required this.efficiency,
    required this.amount,
  });

  final int year;
  final int month;
  final int distance;
  final double efficiency;
  final double amount;
}

class FuelAnalyticsReport {
  const FuelAnalyticsReport({
    required this.monthlySummaries,
    required this.tripPoints,
  });

  factory FuelAnalyticsReport.fromRecords(List<FuelRecord> records) {
    final sortedRecords = [...records]
      ..sort((a, b) => a.odometer.compareTo(b.odometer));
    final monthData = <String, _MutableMonthlyFuelSummary>{};
    final tripPoints = <FuelEfficiencyTripPoint>[];

    for (final record in sortedRecords) {
      final key = _monthKey(record.fueledAt.year, record.fueledAt.month);
      final summary = monthData.putIfAbsent(
        key,
        () => _MutableMonthlyFuelSummary(
          year: record.fueledAt.year,
          month: record.fueledAt.month,
        ),
      );
      summary.fuelCost += record.amount;
    }

    for (var index = 1; index < sortedRecords.length; index++) {
      final previous = sortedRecords[index - 1];
      final current = sortedRecords[index];
      final distance = current.odometer - previous.odometer;

      if (distance <= 0 || current.fuelVolume <= 0) {
        continue;
      }

      final efficiency = distance / current.fuelVolume;
      final key = _monthKey(current.fueledAt.year, current.fueledAt.month);
      final summary = monthData.putIfAbsent(
        key,
        () => _MutableMonthlyFuelSummary(
          year: current.fueledAt.year,
          month: current.fueledAt.month,
        ),
      );
      summary.distance += distance;
      summary.fuelVolume += current.fuelVolume;
      tripPoints.add(
        FuelEfficiencyTripPoint(
          year: current.fueledAt.year,
          month: current.fueledAt.month,
          distance: distance,
          efficiency: efficiency,
          amount: current.amount,
        ),
      );
    }

    final monthlySummaries = monthData.values
        .map(
          (summary) => MonthlyFuelSummary(
            year: summary.year,
            month: summary.month,
            fuelCost: summary.fuelCost,
            distance: summary.distance,
            fuelVolume: summary.fuelVolume,
          ),
        )
        .toList()
      ..sort((a, b) {
        final yearCompare = a.year.compareTo(b.year);

        if (yearCompare != 0) {
          return yearCompare;
        }

        return a.month.compareTo(b.month);
      });

    return FuelAnalyticsReport(
      monthlySummaries: monthlySummaries,
      tripPoints: tripPoints,
    );
  }

  final List<MonthlyFuelSummary> monthlySummaries;
  final List<FuelEfficiencyTripPoint> tripPoints;

  bool get hasMonthlyEfficiency {
    return monthlySummaries.any((summary) => summary.averageEfficiency != null);
  }

  bool get hasMonthlyCost {
    return monthlySummaries.any((summary) => summary.fuelCost > 0);
  }

  bool get hasTripPoints => tripPoints.isNotEmpty;
}

class _MutableMonthlyFuelSummary {
  _MutableMonthlyFuelSummary({
    required this.year,
    required this.month,
  });

  final int year;
  final int month;
  double fuelCost = 0;
  int distance = 0;
  double fuelVolume = 0;
}

String _monthKey(int year, int month) {
  return '$year-${month.toString().padLeft(2, '0')}';
}

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

    final validFuelVolumes = records
        .map((record) => record.fuelVolume)
        .where((fuelVolume) => fuelVolume > 0)
        .toList();

    if (validFuelVolumes.isNotEmpty) {
      final averageFuelVolume =
          validFuelVolumes.fold<double>(0, (total, volume) => total + volume) /
              validFuelVolumes.length;
      final minimumRegularFuelVolume = averageFuelVolume / 2;
      final regularFuelVolumes = validFuelVolumes
          .where((fuelVolume) => fuelVolume > minimumRegularFuelVolume)
          .toList();

      if (regularFuelVolumes.isNotEmpty) {
        estimatedTankVolume = regularFuelVolumes.fold<double>(
              0,
              (total, volume) => total + volume,
            ) /
            regularFuelVolumes.length;
      }
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
