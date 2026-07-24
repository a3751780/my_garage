import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'trip_record.dart';

class TripRecordsRepository {
  const TripRecordsRepository(this._client);

  static const _recordsTable = 'trip_records';
  static const _imagesTable = 'trip_record_images';
  static const _imagesBucket = 'trip-record-images';

  final SupabaseClient _client;

  Future<List<TripRecord>> fetchMonthRecords(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    return _fetchRecords(
      startDate: start,
      endDateExclusive: end,
    );
  }

  Future<List<TripRecord>> fetchRecordsByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return _fetchRecords(
      startDate: start,
      endDateExclusive: end,
    );
  }

  Future<void> addTripRecord(NewTripRecordInput input) async {
    final userId = _requireUserId();
    final row = await _client
        .from(_recordsTable)
        .insert({
          'user_id': userId,
          'vehicle_id': input.vehicleId,
          'title': input.title,
          'content': input.content,
          'trip_date': _formatDate(input.tripDate),
          'odometer': input.odometer,
          'location': input.location,
          'location_latitude': input.locationLatitude,
          'location_longitude': input.locationLongitude,
          'cost': input.cost,
        })
        .select('id')
        .single();
    final tripRecordId = row['id'] as String;

    if (input.images.isEmpty) {
      return;
    }

    final imageRows = <Map<String, dynamic>>[];

    for (var index = 0; index < input.images.length; index++) {
      final image = input.images[index];
      final imagePath = await _uploadImage(
        userId: userId,
        tripRecordId: tripRecordId,
        bytes: image.bytes,
        fileName: image.fileName,
      );

      imageRows.add({
        'trip_record_id': tripRecordId,
        'image_path': imagePath,
        'sort_order': index,
      });
    }

    await _client.from(_imagesTable).insert(imageRows);
  }

  Future<List<TripRecord>> _fetchRecords({
    required DateTime startDate,
    required DateTime endDateExclusive,
  }) async {
    final userId = _requireUserId();
    final rows = await _client
        .from(_recordsTable)
        .select('*, vehicles(model), trip_record_images(*)')
        .eq('user_id', userId)
        .gte('trip_date', _formatDate(startDate))
        .lt('trip_date', _formatDate(endDateExclusive))
        .order('trip_date', ascending: false)
        .order('created_at', ascending: false);

    return rows.map<TripRecord>((row) {
      final json = Map<String, dynamic>.from(row as Map);
      final imageRows = (json['trip_record_images'] as List<dynamic>? ?? [])
          .map((imageRow) => Map<String, dynamic>.from(imageRow as Map))
          .toList()
        ..sort((a, b) {
          final sortCompare = (a['sort_order'] as int? ?? 0)
              .compareTo(b['sort_order'] as int? ?? 0);

          if (sortCompare != 0) {
            return sortCompare;
          }

          return (a['created_at'] as String)
              .compareTo(b['created_at'] as String);
        });

      final images = imageRows.map((imageJson) {
        final imagePath = imageJson['image_path'] as String;
        return TripRecordImage.fromJson(
          imageJson,
          imageUrl: _client.storage.from(_imagesBucket).getPublicUrl(imagePath),
        );
      }).toList();

      return TripRecord.fromJson(json).copyWith(images: images);
    }).toList();
  }

  Future<String> _uploadImage({
    required String userId,
    required String tripRecordId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final extension = _fileExtension(fileName);
    final path =
        '$userId/$tripRecordId/${DateTime.now().microsecondsSinceEpoch}$extension';

    await _client.storage.from(_imagesBucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: false),
        );

    return path;
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw StateError('請先登入後再管理騎旅紀錄');
    }

    return userId;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _fileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '.jpg';
    }

    return fileName.substring(dotIndex).toLowerCase();
  }
}
