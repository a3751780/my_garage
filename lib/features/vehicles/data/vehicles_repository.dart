import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'vehicle.dart';

class VehiclesRepository {
  const VehiclesRepository(this._client);

  static const _tableName = 'vehicles';
  static const _coverBucket = 'vehicle-covers';

  final SupabaseClient _client;

  Future<List<Vehicle>> fetchVehicles() async {
    final userId = _requireUserId();
    final rows = await _client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map<Vehicle>((row) {
      final json = Map<String, dynamic>.from(row as Map);
      final coverImagePath = json['cover_image_path'] as String?;

      return Vehicle.fromJson(
        json,
        coverImageUrl: coverImagePath == null
            ? null
            : _client.storage.from(_coverBucket).getPublicUrl(coverImagePath),
      );
    }).toList();
  }

  Future<Vehicle> addVehicle(NewVehicleInput input) async {
    final userId = _requireUserId();
    final coverImagePath = await _uploadCoverImage(
      userId: userId,
      bytes: input.coverImageBytes,
      fileName: input.coverImageFileName,
    );

    final row = await _client
        .from(_tableName)
        .insert({
          'user_id': userId,
          'model': input.model,
          'year': input.year,
          'initial_mileage': input.initialMileage,
          'current_mileage': input.currentMileage,
          'acquisition_cost': input.acquisitionCost,
          'cover_image_path': coverImagePath,
        })
        .select()
        .single();

    return Vehicle.fromJson(
      row,
      coverImageUrl: coverImagePath == null
          ? null
          : _client.storage.from(_coverBucket).getPublicUrl(coverImagePath),
    );
  }

  Future<Vehicle> updateCurrentMileage({
    required String vehicleId,
    required int currentMileage,
  }) async {
    final userId = _requireUserId();
    final row = await _client
        .from(_tableName)
        .update({'current_mileage': currentMileage})
        .eq('id', vehicleId)
        .eq('user_id', userId)
        .select()
        .single();
    final json = Map<String, dynamic>.from(row as Map);
    final coverImagePath = json['cover_image_path'] as String?;

    return Vehicle.fromJson(
      json,
      coverImageUrl: coverImagePath == null
          ? null
          : _client.storage.from(_coverBucket).getPublicUrl(coverImagePath),
    );
  }

  Future<Vehicle> updateVehicleCoverImage({
    required String vehicleId,
    required List<int> bytes,
    required String fileName,
    String? previousCoverImagePath,
  }) async {
    final userId = _requireUserId();
    final coverImagePath = await _uploadCoverImage(
      userId: userId,
      bytes: bytes,
      fileName: fileName,
    );

    final row = await _client
        .from(_tableName)
        .update({'cover_image_path': coverImagePath})
        .eq('id', vehicleId)
        .eq('user_id', userId)
        .select()
        .single();

    if (previousCoverImagePath != null &&
        previousCoverImagePath != coverImagePath) {
      await _removeCoverImage(previousCoverImagePath);
    }

    return Vehicle.fromJson(
      row,
      coverImageUrl: coverImagePath == null
          ? null
          : _client.storage.from(_coverBucket).getPublicUrl(coverImagePath),
    );
  }

  Future<String?> _uploadCoverImage({
    required String userId,
    required List<int>? bytes,
    required String? fileName,
  }) async {
    if (bytes == null || fileName == null) {
      return null;
    }

    final extension = _fileExtension(fileName);
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}$extension';

    await _client.storage.from(_coverBucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: false),
        );

    return path;
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw StateError('請先登入後再管理車輛');
    }

    return userId;
  }

  Future<void> _removeCoverImage(String path) async {
    try {
      await _client.storage.from(_coverBucket).remove([path]);
    } catch (_) {
      // The database already points to the new image; stale storage cleanup can
      // be retried later without blocking the user from changing the cover.
    }
  }

  String _fileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '.jpg';
    }

    return fileName.substring(dotIndex).toLowerCase();
  }
}
