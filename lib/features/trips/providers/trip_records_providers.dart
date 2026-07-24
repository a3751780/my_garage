import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_providers.dart';
import '../data/trip_record.dart';
import '../data/trip_records_repository.dart';

final tripRecordsRepositoryProvider = Provider<TripRecordsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TripRecordsRepository(client);
});

final tripMonthRecordsProvider =
    FutureProvider.autoDispose.family<List<TripRecord>, DateTime>((ref, month) {
  final repository = ref.watch(tripRecordsRepositoryProvider);
  return repository.fetchMonthRecords(month);
});

final tripDateRecordsProvider =
    FutureProvider.autoDispose.family<List<TripRecord>, DateTime>((ref, date) {
  final repository = ref.watch(tripRecordsRepositoryProvider);
  return repository.fetchRecordsByDate(date);
});
