import 'package:supabase_flutter/supabase_flutter.dart';

import 'maintenance_record.dart';

class MaintenanceRecordsRepository {
  const MaintenanceRecordsRepository(this._client);

  static const _tableName = 'maintenance_records';

  final SupabaseClient _client;

  Future<List<MaintenanceRecord>> fetchMaintenanceRecords(
    String vehicleId,
  ) async {
    final userId = _requireUserId();
    final rows = await _client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .eq('vehicle_id', vehicleId)
        .order('serviced_at', ascending: false)
        .order('created_at', ascending: false);

    return rows.map<MaintenanceRecord>((row) {
      return MaintenanceRecord.fromJson(
        Map<String, dynamic>.from(row as Map),
      );
    }).toList();
  }

  Future<void> addMaintenanceRecord(NewMaintenanceRecordInput input) async {
    final userId = _requireUserId();

    await _client.from(_tableName).insert({
      'user_id': userId,
      'vehicle_id': input.vehicleId,
      'item': input.item,
      'serviced_at': _formatDate(input.servicedAt),
      'odometer': input.odometer,
      'amount': input.amount,
      'service_type': input.serviceType.value,
      'note': input.note,
    });

    await _client
        .from('vehicles')
        .update({'current_mileage': input.odometer})
        .eq('id', input.vehicleId)
        .eq('user_id', userId);
  }

  Future<void> updateMaintenanceRecord({
    required String recordId,
    required NewMaintenanceRecordInput input,
  }) async {
    final userId = _requireUserId();

    await _client
        .from(_tableName)
        .update({
          'item': input.item,
          'serviced_at': _formatDate(input.servicedAt),
          'odometer': input.odometer,
          'amount': input.amount,
          'service_type': input.serviceType.value,
          'note': input.note,
        })
        .eq('id', recordId)
        .eq('vehicle_id', input.vehicleId)
        .eq('user_id', userId);

    await _client
        .from('vehicles')
        .update({'current_mileage': input.odometer})
        .eq('id', input.vehicleId)
        .eq('user_id', userId);
  }

  Future<void> deleteMaintenanceRecord({
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
      throw StateError('請先登入後再管理保養改裝紀錄');
    }

    return userId;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
