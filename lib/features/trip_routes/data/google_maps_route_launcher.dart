import 'package:url_launcher/url_launcher.dart';

import 'trip_route.dart';

class GoogleMapsRouteLauncher {
  const GoogleMapsRouteLauncher();

  Future<bool> openRoute(TripRoute route) async {
    final uri = buildCurrentLocationNavigationUri(route);

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<bool> openPlannedRoute(TripRoute route) async {
    final uri = buildPlannedDirectionsUri(route);

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Uri buildCurrentLocationNavigationUri(TripRoute route) {
    final destination = route.destination;

    if (destination == null) {
      throw ArgumentError('路線需要終點');
    }

    final queryParameters = _baseQueryParameters(route);

    queryParameters.addAll({
      'destination': _locationValue(destination),
      'dir_action': 'navigate',
    });

    if (destination.placeId?.isNotEmpty == true) {
      queryParameters['destination_place_id'] = destination.placeId!;
    }

    final waypoints = _currentLocationWaypoints(route);
    _addWaypoints(queryParameters, waypoints);

    return _directionsUri(queryParameters);
  }

  Uri buildPlannedDirectionsUri(TripRoute route) {
    final origin = route.origin;
    final destination = route.destination;

    if (origin == null || destination == null) {
      throw ArgumentError('路線需要起點與終點');
    }

    final queryParameters = _baseQueryParameters(route);

    queryParameters.addAll({
      'origin': _locationValue(origin),
      'destination': _locationValue(destination),
    });

    if (origin.placeId?.isNotEmpty == true) {
      queryParameters['origin_place_id'] = origin.placeId!;
    }

    if (destination.placeId?.isNotEmpty == true) {
      queryParameters['destination_place_id'] = destination.placeId!;
    }

    _addWaypoints(queryParameters, route.waypoints);

    return _directionsUri(queryParameters);
  }

  List<TripRouteStop> _currentLocationWaypoints(TripRoute route) {
    final origin = route.origin;

    if (origin == null) {
      return route.waypoints;
    }

    return [
      origin,
      ...route.waypoints,
    ];
  }

  Map<String, String> _baseQueryParameters(TripRoute route) {
    return {
      'api': '1',
      'travelmode': _toMapsTravelMode(route.travelMode),
    };
  }

  void _addWaypoints(
    Map<String, String> queryParameters,
    List<TripRouteStop> waypoints,
  ) {
    if (waypoints.isNotEmpty) {
      queryParameters['waypoints'] = waypoints.map(_locationValue).join('|');

      final waypointPlaceIds = waypoints
          .map((waypoint) => waypoint.placeId)
          .whereType<String>()
          .where((placeId) => placeId.isNotEmpty)
          .toList();
      if (waypointPlaceIds.length == waypoints.length) {
        queryParameters['waypoint_place_ids'] = waypointPlaceIds.join('|');
      }
    }
  }

  Uri _directionsUri(Map<String, String> queryParameters) {
    return Uri.https(
      'www.google.com',
      '/maps/dir/',
      queryParameters,
    );
  }

  String _locationValue(TripRouteStop stop) {
    if (stop.name.trim().isNotEmpty && stop.placeId?.isNotEmpty == true) {
      return stop.name;
    }

    return '${stop.latitude},${stop.longitude}';
  }

  String _toMapsTravelMode(String travelMode) {
    return switch (travelMode) {
      'two-wheeler' => 'two-wheeler',
      'driving' => 'driving',
      _ => 'two-wheeler',
    };
  }
}
