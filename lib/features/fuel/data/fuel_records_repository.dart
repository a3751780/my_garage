import 'package:supabase_flutter/supabase_flutter.dart';

import 'fuel_record.dart';

class FuelRecordsRepository {
  const FuelRecordsRepository(this._client);

  static const _tableName = 'fuel_records';

  final SupabaseClient _client;

  Future<List<FuelRecord>> fetchFuelRecords(String vehicleId) async {
    final userId = _requireUserId();
    final rows = await _client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .eq('vehicle_id', vehicleId)
        .order('fueled_at', ascending: false)
        .order('created_at', ascending: false);

    return rows.map<FuelRecord>((row) {
      return FuelRecord.fromJson(Map<String, dynamic>.from(row as Map));
    }).toList();
  }

  Future<void> addFuelRecord(NewFuelRecordInput input) async {
    final userId = _requireUserId();

    await _client.from(_tableName).insert({
      'user_id': userId,
      'vehicle_id': input.vehicleId,
      'fueled_at': _formatDate(input.fueledAt),
      'odometer': input.odometer,
      'fuel_volume': input.fuelVolume,
      'amount': input.amount,
      'fuel_type': input.fuelType,
      'note': input.note,
    });

    await _client
        .from('vehicles')
        .update({'current_mileage': input.odometer})
        .eq('id', input.vehicleId)
        .eq('user_id', userId);
  }

  Future<void> updateFuelRecord({
    required String recordId,
    required NewFuelRecordInput input,
  }) async {
    final userId = _requireUserId();

    await _client
        .from(_tableName)
        .update({
          'fueled_at': _formatDate(input.fueledAt),
          'odometer': input.odometer,
          'fuel_volume': input.fuelVolume,
          'amount': input.amount,
          'fuel_type': input.fuelType,
          'note': input.note,
        })
        .eq('id', recordId)
        .eq('user_id', userId)
        .eq('vehicle_id', input.vehicleId);

    await _client
        .from('vehicles')
        .update({'current_mileage': input.odometer})
        .eq('id', input.vehicleId)
        .eq('user_id', userId);
  }

  Future<void> deleteFuelRecord({
    required String recordId,
    required String vehicleId,
  }) async {
    final userId = _requireUserId();

    await _client
        .from(_tableName)
        .delete()
        .eq('id', recordId)
        .eq('vehicle_id', vehicleId)
        .eq('user_id', userId);
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw StateError('請先登入後再管理加油紀錄');
    }

    return userId;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
