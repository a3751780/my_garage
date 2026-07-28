import 'package:supabase_flutter/supabase_flutter.dart';

import 'trip_route.dart';

class TripRoutesRepository {
  const TripRoutesRepository(this._client);

  static const _routesTable = 'trip_routes';
  static const _stopsTable = 'trip_route_stops';

  final SupabaseClient _client;

  Future<List<TripRoute>> fetchRoutes() async {
    final userId = _requireUserId();
    final rows = await _client
        .from(_routesTable)
        .select('*, trip_route_stops(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map<TripRoute>((row) {
      final json = Map<String, dynamic>.from(row as Map);
      final stopRows = (json['trip_route_stops'] as List<dynamic>? ?? [])
          .map((stopRow) => Map<String, dynamic>.from(stopRow as Map))
          .toList()
        ..sort((a, b) {
          return (a['stop_order'] as int? ?? 0)
              .compareTo(b['stop_order'] as int? ?? 0);
        });

      final stops = stopRows.map(TripRouteStop.fromJson).toList();
      return TripRoute.fromJson(json, stops: stops);
    }).toList();
  }

  Future<void> addRoute(NewTripRouteInput input) async {
    final userId = _requireUserId();

    _validateRouteInput(input);

    final routeRow = await _client
        .from(_routesTable)
        .insert({
          'user_id': userId,
          'name': input.name,
          'description': input.description,
          'travel_mode': input.travelMode,
        })
        .select('id')
        .single();
    final routeId = routeRow['id'] as String;

    final stopRows = _buildStopRows(
      routeId: routeId,
      stops: input.stops,
    );
    await _client.from(_stopsTable).insert(stopRows);
  }

  Future<void> updateRoute({
    required String routeId,
    required NewTripRouteInput input,
  }) async {
    final userId = _requireUserId();
    _validateRouteInput(input);

    await _client
        .from(_routesTable)
        .update({
          'name': input.name,
          'description': input.description,
          'travel_mode': input.travelMode,
          'distance_meters': null,
          'duration_seconds': null,
          'encoded_polyline': null,
        })
        .eq('id', routeId)
        .eq('user_id', userId);

    await _client.from(_stopsTable).delete().eq('route_id', routeId);

    final stopRows = _buildStopRows(
      routeId: routeId,
      stops: input.stops,
    );
    await _client.from(_stopsTable).insert(stopRows);
  }

  Future<void> deleteRoute(String routeId) async {
    final userId = _requireUserId();

    await _client
        .from(_routesTable)
        .delete()
        .eq('id', routeId)
        .eq('user_id', userId);
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw StateError('請先登入後再管理騎旅路線');
    }

    return userId;
  }

  void _validateRouteInput(NewTripRouteInput input) {
    if (input.stops.length < 2) {
      throw ArgumentError('路線至少需要起點與終點');
    }
  }

  List<Map<String, dynamic>> _buildStopRows({
    required String routeId,
    required List<NewTripRouteStopInput> stops,
  }) {
    final stopRows = <Map<String, dynamic>>[];

    for (var index = 0; index < stops.length; index++) {
      final stop = stops[index];
      stopRows.add({
        'route_id': routeId,
        'stop_order': index,
        'name': stop.name,
        'place_id': stop.placeId,
        'address': stop.address,
        'latitude': stop.latitude,
        'longitude': stop.longitude,
        'is_origin': index == 0,
        'is_destination': index == stops.length - 1,
      });
    }

    return stopRows;
  }
}
