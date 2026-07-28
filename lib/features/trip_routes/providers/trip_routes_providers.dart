import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_providers.dart';
import '../data/google_maps_route_launcher.dart';
import '../data/trip_route.dart';
import '../data/trip_routes_repository.dart';

final tripRoutesRepositoryProvider = Provider<TripRoutesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TripRoutesRepository(client);
});

final googleMapsRouteLauncherProvider =
    Provider<GoogleMapsRouteLauncher>((ref) {
  return const GoogleMapsRouteLauncher();
});

final tripRoutesProvider = FutureProvider.autoDispose<List<TripRoute>>((ref) {
  final repository = ref.watch(tripRoutesRepositoryProvider);
  return repository.fetchRoutes();
});
