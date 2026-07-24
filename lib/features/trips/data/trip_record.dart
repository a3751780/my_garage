class TripRecordImage {
  const TripRecordImage({
    required this.id,
    required this.tripRecordId,
    required this.imagePath,
    required this.sortOrder,
    required this.createdAt,
    this.imageUrl,
  });

  factory TripRecordImage.fromJson(
    Map<String, dynamic> json, {
    String? imageUrl,
  }) {
    return TripRecordImage(
      id: json['id'] as String,
      tripRecordId: json['trip_record_id'] as String,
      imagePath: json['image_path'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      imageUrl: imageUrl,
    );
  }

  final String id;
  final String tripRecordId;
  final String imagePath;
  final int sortOrder;
  final DateTime createdAt;
  final String? imageUrl;
}

class TripRecord {
  const TripRecord({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.title,
    required this.tripDate,
    required this.createdAt,
    required this.images,
    this.vehicleModel,
    this.content,
    this.odometer,
    this.location,
    this.locationLatitude,
    this.locationLongitude,
    this.cost = 0,
  });

  factory TripRecord.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicles'] as Map<String, dynamic>?;

    return TripRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      tripDate: DateTime.parse(json['trip_date'] as String),
      odometer: json['odometer'] as int?,
      location: json['location'] as String?,
      locationLatitude: (json['location_latitude'] as num?)?.toDouble(),
      locationLongitude: (json['location_longitude'] as num?)?.toDouble(),
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      vehicleModel: vehicle?['model'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      images: const [],
    );
  }

  final String id;
  final String userId;
  final String vehicleId;
  final String title;
  final String? content;
  final DateTime tripDate;
  final int? odometer;
  final String? location;
  final double? locationLatitude;
  final double? locationLongitude;
  final double cost;
  final String? vehicleModel;
  final DateTime createdAt;
  final List<TripRecordImage> images;

  TripRecord copyWith({
    List<TripRecordImage>? images,
  }) {
    return TripRecord(
      id: id,
      userId: userId,
      vehicleId: vehicleId,
      title: title,
      content: content,
      tripDate: tripDate,
      odometer: odometer,
      location: location,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      cost: cost,
      vehicleModel: vehicleModel,
      createdAt: createdAt,
      images: images ?? this.images,
    );
  }
}

class NewTripRecordInput {
  const NewTripRecordInput({
    required this.vehicleId,
    required this.title,
    required this.tripDate,
    this.content,
    this.odometer,
    this.location,
    this.locationLatitude,
    this.locationLongitude,
    this.cost = 0,
    this.images = const [],
  });

  final String vehicleId;
  final String title;
  final String? content;
  final DateTime tripDate;
  final int? odometer;
  final String? location;
  final double? locationLatitude;
  final double? locationLongitude;
  final double cost;
  final List<NewTripRecordImageInput> images;
}

class NewTripRecordImageInput {
  const NewTripRecordImageInput({
    required this.bytes,
    required this.fileName,
  });

  final List<int> bytes;
  final String fileName;
}
