import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_providers.dart';
import '../data/fuel_record.dart';
import '../data/fuel_records_repository.dart';

final fuelRecordsRepositoryProvider = Provider<FuelRecordsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FuelRecordsRepository(client);
});

final fuelRecordsProvider =
    FutureProvider.autoDispose.family<List<FuelRecord>, String>((
  ref,
  vehicleId,
) {
  final repository = ref.watch(fuelRecordsRepositoryProvider);
  return repository.fetchFuelRecords(vehicleId);
});
