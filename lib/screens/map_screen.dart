import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/park_service.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  LatLng _currentPosition = const LatLng(4.6583, -74.0939);
  bool _isLoading = true;
  bool _hasLocation = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _initLocationAndParks();
  }

  Future<void> _initLocationAndParks() async {
    if (mounted) setState(() => _isLoading = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        final Position pos = await _getPosition();
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _hasLocation = true;
        if (_mapReady) _mapController.move(_currentPosition, 14);
      } catch (e) {
        debugPrint('No se pudo obtener la ubicación: $e');
      }
    }

    final parks = await ParkService.fetchNearbyParks(
      _currentPosition.latitude,
      _currentPosition.longitude,
    );

    if (!mounted) return;
    setState(() {
      _markers.clear();
      for (final park in parks) {
        _markers.add(
          Marker(
            point: LatLng(park['lat'], park['lon']),
            width: 40,
            height: 40,
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: () => _showParkInfo(park['name']),
              child: const Icon(
                Icons.location_on,
                color: AppTheme.primaryGreen,
                size: 40,
                semanticLabel: 'Parque',
              ),
            ),
          ),
        );
      }
      _isLoading = false;
    });

    if (parks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontraron parques cercanos.')),
      );
    }
  }

  Future<Position> _getPosition() async {
    try {
      return await Geolocator.getCurrentPosition();
    } on LocationServiceDisabledException {
      return Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 20),
      );
    }
  }

  void _showParkInfo(String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryGreen,
          content: Row(
            children: [
              const Icon(Icons.park, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('Zona verde cercana'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parques Cercanos')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 14,
              onMapReady: () {
                _mapReady = true;
                _mapController.move(_currentPosition, 14);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.taller_movilidad',
              ),
              MarkerLayer(markers: _markers),
              if (_hasLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(blurRadius: 4, color: Colors.black26),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('Colaboradores de OpenStreetMap'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: _isLoading
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Buscando parques cercanos…'),
                          ],
                        ),
                      ),
                    )
                  : Chip(
                      avatar: const Icon(Icons.park, color: Colors.green),
                      label: Text('${_markers.length} parques en 3 km'),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'ubicacion',
            tooltip: 'Mi ubicación',
            onPressed: () => _mapController.move(_currentPosition, 15),
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'actualizar',
            tooltip: 'Actualizar parques',
            onPressed: _isLoading ? null : _initLocationAndParks,
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
