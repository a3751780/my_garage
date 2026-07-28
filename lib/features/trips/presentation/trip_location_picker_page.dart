import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/config/google_maps_config.dart';
import '../data/google_places_service.dart';

class TripLocationSelection {
  const TripLocationSelection({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.address,
  });

  final String name;
  final String? placeId;
  final String? address;
  final double latitude;
  final double longitude;
}

class TripLocationPickerPage extends StatefulWidget {
  const TripLocationPickerPage({
    super.key,
    this.initialName,
    this.initialPlaceId,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  });

  final String? initialName;
  final String? initialPlaceId;
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<TripLocationPickerPage> createState() => _TripLocationPickerPageState();
}

class _TripLocationPickerPageState extends State<TripLocationPickerPage> {
  static const _defaultLocation = LatLng(25.033964, 121.564468);

  final _searchController = TextEditingController();
  late final GooglePlacesService _placesService;
  late LatLng _selectedLocation;
  late String _selectedName;
  String? _selectedPlaceId;
  String? _selectedAddress;
  GoogleMapController? _mapController;
  List<GooglePlaceResult> _placeResults = const [];
  bool _isResolvingName = false;
  bool _isSearchingPlaces = false;
  String? _placesMessage;

  @override
  void initState() {
    super.initState();
    _placesService = GooglePlacesService(
      apiKey: GoogleMapsConfig.fromDotEnv().placesApiKey,
    );
    _selectedLocation = LatLng(
      widget.initialLatitude ?? _defaultLocation.latitude,
      widget.initialLongitude ?? _defaultLocation.longitude,
    );
    _selectedName = widget.initialName ?? '台北市';
    _selectedPlaceId = widget.initialPlaceId;
    _selectedAddress = widget.initialAddress;
    _searchController.text = widget.initialName ?? '';

    if (widget.initialName == null) {
      _loadNearbyPlaces(_selectedLocation);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇騎旅地點'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('trip_location'),
                position: _selectedLocation,
                infoWindow: InfoWindow(title: _selectedName),
              ),
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (position) {
              setState(() {
                _selectedLocation = position;
                _selectedName = _formatLatLng(position);
                _selectedPlaceId = null;
                _selectedAddress = null;
                _searchController.clear();
              });
              _loadNearbyPlaces(position);
            },
          ),
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: SafeArea(
              child: _PlaceSearchBar(
                controller: _searchController,
                isSearching: _isSearchingPlaces,
                onSearch: _searchPlacesByText,
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _placeResults = const [];
                    _placesMessage = null;
                  });
                },
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isResolvingName ? '正在取得地點名稱...' : _selectedName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatLatLng(_selectedLocation),
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    if (_placesMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _placesMessage!,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                    if (_placeResults.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _PlaceResultList(
                        places: _placeResults,
                        selectedLocation: _selectedLocation,
                        onSelect: _selectPlace,
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(
                            TripLocationSelection(
                              name: _selectedName,
                              placeId: _selectedPlaceId,
                              address: _selectedAddress,
                              latitude: _selectedLocation.latitude,
                              longitude: _selectedLocation.longitude,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('使用此地點'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNearbyPlaces(LatLng location) async {
    if (!_placesService.isConfigured) {
      setState(() {
        _placesMessage = '未設定 Places API key，暫時使用地址/座標模式';
        _placeResults = const [];
      });
      await _resolveLocationName(location);
      return;
    }

    setState(() {
      _isSearchingPlaces = true;
      _placesMessage = '正在搜尋附近地標...';
      _placeResults = const [];
    });

    try {
      final places = await _placesService.searchNearbyLandmarks(location);

      if (!mounted) {
        return;
      }

      if (places.isEmpty) {
        setState(() => _placesMessage = '附近找不到明確地標，已改用地址');
        await _resolveLocationName(location);
        return;
      }

      setState(() {
        _placeResults = places;
        _placesMessage = '選一個附近地標，或直接使用目前位置';
      });
      _selectPlace(places.first, moveCamera: false);
    } on GooglePlacesException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _placesMessage = '${error.message}；已改用地址');
      await _resolveLocationName(location);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _placesMessage = '地標搜尋失敗，已改用地址');
      await _resolveLocationName(location);
    } finally {
      if (mounted) {
        setState(() => _isSearchingPlaces = false);
      }
    }
  }

  Future<void> _searchPlacesByText() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return;
    }

    if (!_placesService.isConfigured) {
      setState(() => _placesMessage = '請先設定 GOOGLE_PLACES_API_KEY');
      return;
    }

    setState(() {
      _isSearchingPlaces = true;
      _placesMessage = '正在搜尋「$query」...';
      _placeResults = const [];
    });

    try {
      final places = await _placesService.searchText(
        query: query,
        locationBias: _selectedLocation,
      );

      if (!mounted) {
        return;
      }

      if (places.isEmpty) {
        setState(() => _placesMessage = '找不到符合的地標');
        return;
      }

      setState(() {
        _placeResults = places;
        _placesMessage = '選擇你這次騎旅抵達的地標';
      });
      _selectPlace(places.first);
    } on GooglePlacesException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _placesMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _placesMessage = '地標搜尋失敗，請確認 Places API 是否啟用');
    } finally {
      if (mounted) {
        setState(() => _isSearchingPlaces = false);
      }
    }
  }

  void _selectPlace(
    GooglePlaceResult place, {
    bool moveCamera = true,
  }) {
    setState(() {
      _selectedLocation = place.latLng;
      _selectedName = place.name;
      _selectedPlaceId = place.id;
      _selectedAddress = place.address;
      _searchController.text = place.name;
    });

    if (moveCamera) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(place.latLng, 16),
      );
    }
  }

  Future<void> _resolveLocationName(LatLng location) async {
    setState(() => _isResolvingName = true);

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (!mounted || placemarks.isEmpty) {
        return;
      }

      final name = _formatPlacemark(placemarks.first);
      setState(() {
        _selectedName = name.isEmpty ? _formatLatLng(location) : name;
        _selectedPlaceId = null;
        _selectedAddress = _selectedName;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedName = _formatLatLng(location);
        _selectedPlaceId = null;
        _selectedAddress = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isResolvingName = false);
      }
    }
  }

  String _formatPlacemark(Placemark placemark) {
    return [
      placemark.name,
      placemark.thoroughfare,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
    ]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet()
        .join(' ');
  }

  String _formatLatLng(LatLng location) {
    return '${location.latitude.toStringAsFixed(6)}, '
        '${location.longitude.toStringAsFixed(6)}';
  }
}

class _PlaceSearchBar extends StatelessWidget {
  const _PlaceSearchBar({
    required this.controller,
    required this.isSearching,
    required this.onSearch,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: 6,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '搜尋地標、景點、店家',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  tooltip: '清除',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
              IconButton(
                tooltip: '搜尋',
                onPressed: isSearching ? null : onSearch,
                icon: isSearching
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
        onSubmitted: (_) => onSearch(),
      ),
    );
  }
}

class _PlaceResultList extends StatelessWidget {
  const _PlaceResultList({
    required this.places,
    required this.selectedLocation,
    required this.onSelect,
  });

  final List<GooglePlaceResult> places;
  final LatLng selectedLocation;
  final ValueChanged<GooglePlaceResult> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      child: ListView.separated(
        itemCount: places.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final place = places[index];
          final isSelected = place.latitude == selectedLocation.latitude &&
              place.longitude == selectedLocation.longitude;

          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isSelected ? Icons.check_circle : Icons.place_outlined,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(
              place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: place.address == null
                ? null
                : Text(
                    place.address!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () => onSelect(place),
          );
        },
      ),
    );
  }
}
