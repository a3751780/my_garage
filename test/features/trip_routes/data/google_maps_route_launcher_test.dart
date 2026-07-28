import 'package:flutter_test/flutter_test.dart';
import 'package:my_garage/features/trip_routes/data/google_maps_route_launcher.dart';
import 'package:my_garage/features/trip_routes/data/trip_route.dart';

void main() {
  group('GoogleMapsRouteLauncher', () {
    test('builds navigation URL from current location by omitting origin', () {
      final route = _route();

      final uri =
          const GoogleMapsRouteLauncher().buildCurrentLocationNavigationUri(
        route,
      );

      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters.containsKey('origin'), isFalse);
      expect(uri.queryParameters.containsKey('origin_place_id'), isFalse);
      expect(uri.queryParameters['destination'], '淡水老街');
      expect(
        uri.queryParameters['destination_place_id'],
        'place-destination',
      );
      expect(uri.queryParameters['waypoints'], '台北車站|富貴角燈塔');
      expect(
        uri.queryParameters['waypoint_place_ids'],
        'place-origin|place-waypoint',
      );
      expect(uri.queryParameters['travelmode'], 'two-wheeler');
      expect(uri.queryParameters['dir_action'], 'navigate');
    });

    test('builds planned directions URL with the saved origin', () {
      final route = _route();

      final uri = const GoogleMapsRouteLauncher().buildPlannedDirectionsUri(
        route,
      );

      expect(uri.queryParameters['origin'], '台北車站');
      expect(uri.queryParameters['origin_place_id'], 'place-origin');
      expect(uri.queryParameters['destination'], '淡水老街');
      expect(
        uri.queryParameters['destination_place_id'],
        'place-destination',
      );
      expect(uri.queryParameters['waypoints'], '富貴角燈塔');
      expect(uri.queryParameters['waypoint_place_ids'], 'place-waypoint');
      expect(uri.queryParameters['travelmode'], 'two-wheeler');
      expect(uri.queryParameters.containsKey('dir_action'), isFalse);
    });
  });
}

TripRoute _route() {
  return TripRoute(
    id: 'route-1',
    userId: 'user-1',
    name: '北海岸小跑',
    travelMode: 'two-wheeler',
    createdAt: DateTime(2026),
    stops: [
      _stop(
        id: 'stop-1',
        order: 0,
        name: '台北車站',
        placeId: 'place-origin',
        isOrigin: true,
      ),
      _stop(
        id: 'stop-2',
        order: 1,
        name: '富貴角燈塔',
        placeId: 'place-waypoint',
      ),
      _stop(
        id: 'stop-3',
        order: 2,
        name: '淡水老街',
        placeId: 'place-destination',
        isDestination: true,
      ),
    ],
  );
}

TripRouteStop _stop({
  required String id,
  required int order,
  required String name,
  String? placeId,
  bool isOrigin = false,
  bool isDestination = false,
}) {
  return TripRouteStop(
    id: id,
    routeId: 'route-1',
    stopOrder: order,
    name: name,
    placeId: placeId,
    latitude: 25.0 + order,
    longitude: 121.0 + order,
    isOrigin: isOrigin,
    isDestination: isDestination,
    createdAt: DateTime(2026),
  );
}
