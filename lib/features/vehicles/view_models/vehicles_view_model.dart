import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vehicle.dart';
import '../data/vehicles_repository.dart';

class VehiclesViewModel extends StateNotifier<AsyncValue<List<Vehicle>>> {
  VehiclesViewModel(this._repository) : super(const AsyncValue.loading());

  final VehiclesRepository _repository;

  Future<void> loadVehicles() async {
    state = const AsyncValue.loading();

    try {
      state = AsyncValue.data(await _repository.fetchVehicles());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addVehicle(NewVehicleInput input) async {
    await _repository.addVehicle(input);
    await loadVehicles();
  }
}
