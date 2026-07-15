import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const defaultOilChangeInterval = 1000;

final oilChangeIntervalProvider =
    FutureProvider.autoDispose.family<int, String>((ref, vehicleId) async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getInt(_oilChangeIntervalKey(vehicleId)) ??
      defaultOilChangeInterval;
});

final oilChangeIntervalRepositoryProvider =
    Provider<OilChangeIntervalRepository>((ref) {
  return const OilChangeIntervalRepository();
});

class OilChangeIntervalRepository {
  const OilChangeIntervalRepository();

  Future<void> saveInterval({
    required String vehicleId,
    required int interval,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_oilChangeIntervalKey(vehicleId), interval);
  }
}

String _oilChangeIntervalKey(String vehicleId) {
  return 'oil_change_interval_$vehicleId';
}
