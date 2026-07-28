class TripRoute {
  const TripRoute({
    required this.id,
    required this.userId,
    required this.name,
    required this.travelMode,
    required this.stops,
    required this.createdAt,
    this.description,
    this.distanceMeters,
    this.durationSeconds,
    this.encodedPolyline,
  });

  factory TripRoute.fromJson(
    Map<String, dynamic> json, {
    List<TripRouteStop> stops = const [],
  }) {
    return TripRoute(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      travelMode: json['travel_mode'] as String? ?? 'two-wheeler',
      distanceMeters: json['distance_meters'] as int?,
      durationSeconds: json['duration_seconds'] as int?,
      encodedPolyline: json['encoded_polyline'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      stops: stops,
    );
  }

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String travelMode;
  final int? distanceMeters;
  final int? durationSeconds;
  final String? encodedPolyline;
  final DateTime createdAt;
  final List<TripRouteStop> stops;

  TripRouteStop? get origin {
    if (stops.isEmpty) {
      return null;
    }

    return stops.firstWhere(
      (stop) => stop.isOrigin,
      orElse: () => stops.first,
    );
  }

  TripRouteStop? get destination {
    if (stops.isEmpty) {
      return null;
    }

    return stops.firstWhere(
      (stop) => stop.isDestination,
      orElse: () => stops.last,
    );
  }

  List<TripRouteStop> get waypoints {
    return stops
        .where((stop) => !stop.isOrigin && !stop.isDestination)
        .toList();
  }
}

class TripRouteStop {
  const TripRouteStop({
    required this.id,
    required this.routeId,
    required this.stopOrder,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isOrigin,
    required this.isDestination,
    required this.createdAt,
    this.placeId,
    this.address,
  });

  factory TripRouteStop.fromJson(Map<String, dynamic> json) {
    return TripRouteStop(
      id: json['id'] as String,
      routeId: json['route_id'] as String,
      stopOrder: json['stop_order'] as int? ?? 0,
      name: json['name'] as String,
      placeId: json['place_id'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isOrigin: json['is_origin'] as bool? ?? false,
      isDestination: json['is_destination'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String routeId;
  final int stopOrder;
  final String name;
  final String? placeId;
  final String? address;
  final double latitude;
  final double longitude;
  final bool isOrigin;
  final bool isDestination;
  final DateTime createdAt;

  String get coordinateLabel {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}

class NewTripRouteInput {
  const NewTripRouteInput({
    required this.name,
    required this.stops,
    this.description,
    this.travelMode = 'two-wheeler',
  });

  final String name;
  final String? description;
  final String travelMode;
  final List<NewTripRouteStopInput> stops;
}

class NewTripRouteStopInput {
  const NewTripRouteStopInput({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.address,
  });

  factory NewTripRouteStopInput.fromStop(TripRouteStop stop) {
    return NewTripRouteStopInput(
      name: stop.name,
      placeId: stop.placeId,
      address: stop.address,
      latitude: stop.latitude,
      longitude: stop.longitude,
    );
  }

  final String name;
  final String? placeId;
  final String? address;
  final double latitude;
  final double longitude;

  String get coordinateLabel {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}
