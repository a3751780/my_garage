import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_providers.dart';
import '../data/vehicle.dart';
import '../data/vehicles_repository.dart';
import '../view_models/vehicles_view_model.dart';

final vehiclesRepositoryProvider = Provider<VehiclesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return VehiclesRepository(client);
});

final vehiclesViewModelProvider =
    StateNotifierProvider<VehiclesViewModel, AsyncValue<List<Vehicle>>>((ref) {
  final repository = ref.watch(vehiclesRepositoryProvider);
  return VehiclesViewModel(repository)..loadVehicles();
});
