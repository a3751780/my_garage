import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_providers.dart';
import '../data/maintenance_record.dart';
import '../data/maintenance_records_repository.dart';

final maintenanceRecordsRepositoryProvider =
    Provider<MaintenanceRecordsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MaintenanceRecordsRepository(client);
});

final maintenanceRecordsProvider =
    FutureProvider.autoDispose.family<List<MaintenanceRecord>, String>((
  ref,
  vehicleId,
) {
  final repository = ref.watch(maintenanceRecordsRepositoryProvider);
  return repository.fetchMaintenanceRecords(vehicleId);
});
