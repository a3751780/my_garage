import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fuel/data/fuel_analytics.dart';
import '../../fuel/data/fuel_record.dart';
import '../../fuel/providers/fuel_records_providers.dart';
import '../../maintenance/data/maintenance_record.dart';
import '../../maintenance/data/oil_change_status.dart';
import '../../maintenance/providers/maintenance_records_providers.dart';
import '../../maintenance/providers/oil_change_preferences_provider.dart';
import '../../vehicles/data/vehicle.dart';
import '../data/garage_home_widget_service.dart';

class GarageHomeWidgetSync extends ConsumerStatefulWidget {
  const GarageHomeWidgetSync({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<GarageHomeWidgetSync> createState() =>
      _GarageHomeWidgetSyncState();
}

class _GarageHomeWidgetSyncState extends ConsumerState<GarageHomeWidgetSync> {
  String? _lastSyncedSignature;

  @override
  Widget build(BuildContext context) {
    final fuelRecordsState = ref.watch(fuelRecordsProvider(widget.vehicle.id));
    final maintenanceRecordsState = ref.watch(
      maintenanceRecordsProvider(widget.vehicle.id),
    );
    final intervalState = ref.watch(
      oilChangeIntervalProvider(widget.vehicle.id),
    );

    fuelRecordsState.whenData((fuelRecords) {
      maintenanceRecordsState.whenData((maintenanceRecords) {
        intervalState.whenData((interval) {
          final signature = _widgetStatusSignature(
            fuelRecords: fuelRecords,
            maintenanceRecords: maintenanceRecords,
            interval: interval,
          );

          if (_lastSyncedSignature == signature) {
            return;
          }

          _lastSyncedSignature = signature;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            GarageHomeWidgetService.updateStatus(
              vehicle: widget.vehicle,
              fuelAnalytics: FuelAnalytics.fromRecords(
                fuelRecords,
                currentMileage: widget.vehicle.currentMileage,
              ),
              oilChangeStatus: OilChangeStatus.fromRecords(
                records: maintenanceRecords,
                currentMileage: widget.vehicle.currentMileage,
                interval: interval,
              ),
            );
          });
        });
      });
    });

    return const SizedBox.shrink();
  }

  String _widgetStatusSignature({
    required List<FuelRecord> fuelRecords,
    required List<MaintenanceRecord> maintenanceRecords,
    required int interval,
  }) {
    final latestFuelOdometer = fuelRecords.isEmpty
        ? 0
        : fuelRecords
            .map((record) => record.odometer)
            .reduce((value, element) => value > element ? value : element);
    final latestMaintenanceOdometer = maintenanceRecords.isEmpty
        ? 0
        : maintenanceRecords
            .map((record) => record.odometer)
            .reduce((value, element) => value > element ? value : element);

    return [
      widget.vehicle.id,
      widget.vehicle.model,
      widget.vehicle.currentMileage,
      fuelRecords.length,
      latestFuelOdometer,
      maintenanceRecords.length,
      latestMaintenanceOdometer,
      interval,
    ].join('|');
  }
}
