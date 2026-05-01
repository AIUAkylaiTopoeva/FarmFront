import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class RouteScreen extends StatefulWidget {
  final List<int> productIds;
  const RouteScreen({super.key, required this.productIds});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  static const _green = Color(0xFF1C4A2A);

  // По умолчанию — центр Бишкека
  double _startLat = 42.8746;
  double _startLon = 74.5698;
  bool _locationLoaded = false;
  String _locationLabel = 'Бишкек (по умолчанию)';

  double _fuelPrice = 67.0;
  double _fuelConsumption = 10.0;
  String _roadQuality = 'medium';
  String _selectedProfile = 'balanced';

  Map<String, dynamic>? _routeData;
  bool _isLoading = false;
  String _error = '';

  final _fuelPriceController = TextEditingController(text: '67');
  final _consumptionController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _fuelPriceController.dispose();
    _consumptionController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _startRoute();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _startRoute();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _startRoute();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _startLat = position.latitude;
          _startLon = position.longitude;
          _locationLoaded = true;
          _locationLabel = 'Моё местоположение';
        });
      }
    } catch (_) {
      // Fallback на Бишкек
    }
    _startRoute();
  }

  void _startRoute() {
    if (widget.productIds.isNotEmpty) _loadRoute();
  }

  Future<void> _loadRoute() async {
    if (widget.productIds.isEmpty) return;
    setState(() { _isLoading = true; _error = ''; });
    try {
      final data = await ApiService.compareRoutes(
        widget.productIds,
        _startLat,
        _startLon,
        fuelPrice: _fuelPrice,
        fuelConsumption: _fuelConsumption,
        roadQuality: _roadQuality,
      );
      if (mounted) setState(() { _routeData = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Map<String, dynamic>? get _currentProfile {
    final profiles = _routeData?['profiles'];
    if (profiles == null) return null;
    final profile = profiles[_selectedProfile];
    if (profile == null) return null;

    final profileRoutes = _routeData?['profile_routes'];
    final route = profileRoutes?[_selectedProfile] as List<dynamic>?;

    return {
      ...Map<String, dynamic>.from(profile as Map),
      'total_distance_km': profile['distance_km'],
      'fuel_cost_som': profile['fuel_cost_som'],
      'estimated_time_min': profile['travel_time_min'],
      'stops': route ?? [],
    };
  }

  // Реальный маршрут по дорогам из OSRM геометрии
  List<LatLng> _extractRealPolyline() {
    if (_routeData == null) return [];

    // Пробуем взять геометрию реального маршрута
    final geometry = _routeData!['route_geometry'] as List<dynamic>?;
    if (geometry != null && geometry.isNotEmpty) {
      return geometry.map((p) {
        final lat = double.tryParse(p['lat'].toString()) ?? 0;
        final lon = double.tryParse(p['lon'].toString()) ?? 0;
        return LatLng(lat, lon);
      }).where((p) => p.latitude != 0).toList();
    }

    // Fallback — прямые линии между точками
    return _extractFallbackPolyline();
  }

  List<LatLng> _extractFallbackPolyline() {
    if (_routeData == null) return [];
    final profileRoutes = _routeData!['profile_routes'];
    if (profileRoutes == null) return [];
    final route = profileRoutes[_selectedProfile] as List<dynamic>?;
    if (route == null || route.isEmpty) return [];

    final points = <LatLng>[LatLng(_startLat, _startLon)];
    for (final stop in route) {
      final lat = double.tryParse(stop['lat'].toString()) ?? 0;
      final lon = double.tryParse(stop['lon'].toString()) ?? 0;
      if (lat != 0 && lon != 0) points.add(LatLng(lat, lon));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('Маршрут'),
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRoute),
        ],
      ),
      body: widget.productIds.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                // Панель геопозиции
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _locationLoaded ? Icons.my_location : Icons.location_on_outlined,
                        color: _locationLoaded ? Colors.blue : const Color(0xFF888888),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: _locationLoaded ? Colors.blue : const Color(0xFF888888),
                            fontWeight: _locationLoaded ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          setState(() { _locationLoaded = false; _locationLabel = 'Определяем...'; });
                          await _getLocation();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Обновить',
                              style: TextStyle(fontSize: 11, color: Colors.blue,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildParamsPanel(),
                _buildProfileSelector(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: _green),
                              SizedBox(height: 16),
                              Text('Вычисляем оптимальный маршрут...',
                                  style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                              SizedBox(height: 8),
                              Text('Это может занять до 30 секунд',
                                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 11)),
                            ],
                          ),
                        )
                      : _error.isNotEmpty
                          ? _buildError()
                          : _routeData == null
                              ? const SizedBox.shrink()
                              : _buildRouteContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildParamsPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _paramField(_fuelPriceController, 'Цена бензина (сом/л)',
                    Icons.local_gas_station_outlined,
                    onChanged: (v) => _fuelPrice = double.tryParse(v) ?? 67),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _paramField(_consumptionController, 'Расход (л/100 км)',
                    Icons.speed_outlined,
                    onChanged: (v) => _fuelConsumption = double.tryParse(v) ?? 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Дороги: ', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
              ...['good', 'medium', 'bad'].map((q) {
                final label = q == 'good' ? 'Хорошие' : q == 'medium' ? 'Средние' : 'Плохие';
                final sel = _roadQuality == q;
                return GestureDetector(
                  onTap: () => setState(() => _roadQuality = q),
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel ? _green : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                        color: sel ? Colors.white : const Color(0xFF555555))),
                  ),
                );
              }),
              const Spacer(),
              GestureDetector(
                onTap: _loadRoute,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Пересчитать',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paramField(TextEditingController ctrl, String hint, IconData icon,
      {required Function(String) onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(fontSize: 11),
        prefixIcon: Icon(icon, size: 16, color: const Color(0xFF888888)),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _green)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
      ),
    );
  }

  Widget _buildProfileSelector() {
    final profiles = [
      {'id': 'cheapest', 'label': 'Дешевле', 'icon': Icons.savings_outlined},
      {'id': 'balanced', 'label': 'Оптимально', 'icon': Icons.balance_outlined},
      {'id': 'fastest', 'label': 'Быстрее', 'icon': Icons.speed_outlined},
    ];
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: profiles.map((p) {
          final sel = _selectedProfile == p['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedProfile = p['id'] as String),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? _green : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? _green : const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  children: [
                    Icon(p['icon'] as IconData, size: 18,
                        color: sel ? Colors.white : const Color(0xFF666666)),
                    const SizedBox(height: 4),
                    Text(p['label'] as String,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : const Color(0xFF555555))),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRouteContent() {
    final profile = _currentProfile;
    final polyline = _extractRealPolyline();
    final savings = _routeData?['savings'];
    final hasRealRoute = (_routeData?['route_geometry'] as List?)?.isNotEmpty == true;

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: polyline.length < 2
              ? _buildStaticInfo()
              : Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(_startLat, _startLon),
                        initialZoom: 11,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'kg.agropath.app',
                        ),
                        PolylineLayer(polylines: [
                          Polyline(
                            points: polyline,
                            color: _green,
                            strokeWidth: hasRealRoute ? 4 : 2,
                            pattern: hasRealRoute
                                ? const StrokePattern.solid()
                                : const StrokePattern.dotted(),
                          ),
                        ]),
                        MarkerLayer(
                          markers: [
                            // Моя точка
                            Marker(
                              point: LatLng(_startLat, _startLon),
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.my_location, color: Colors.white, size: 16),
                              ),
                            ),
                            // Точки ферм
                            ...(() {
                              final profileRoutes = _routeData?['profile_routes'];
                              final route = profileRoutes?[_selectedProfile] as List<dynamic>?;
                              if (route == null) return <Marker>[];
                              return route.asMap().entries.map((e) {
                                final stop = e.value;
                                final lat = double.tryParse(stop['lat'].toString()) ?? 0;
                                final lon = double.tryParse(stop['lon'].toString()) ?? 0;
                                if (lat == 0) return null;
                                return Marker(
                                  point: LatLng(lat, lon),
                                  child: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: _green, shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Center(
                                      child: Text('${e.key + 1}',
                                          style: const TextStyle(color: Colors.white,
                                              fontSize: 12, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                );
                              }).whereType<Marker>().toList();
                            })(),
                          ],
                        ),
                      ],
                    ),
                    if (!hasRealRoute)
                      Positioned(
                        bottom: 8, left: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'OSRM недоступен — маршрут по прямой (приблизительно)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (profile != null) ...[
                  Row(children: [
                    _statCard(
                      '${(profile['total_distance_km'] ?? profile['distance_km'] ?? 0).toStringAsFixed(1)} км',
                      'Расстояние', Icons.route_outlined, Colors.blue),
                    const SizedBox(width: 10),
                    _statCard(
                      '${(profile['fuel_cost_som'] ?? 0).toStringAsFixed(0)} сом',
                      'Топливо', Icons.local_gas_station_outlined, Colors.orange),
                    const SizedBox(width: 10),
                    _statCard(
                      '${(profile['estimated_time_min'] ?? profile['travel_time_min'] ?? 0).toStringAsFixed(0)} мин',
                      'Время', Icons.access_time_outlined, Colors.purple),
                  ]),
                ],
                if (savings != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.savings_rounded, color: _green, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Экономия vs случайный маршрут',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                              const SizedBox(height: 4),
                              Row(children: [
                                Text('-${(savings['distance_km'] ?? 0).toStringAsFixed(1)} км',
                                    style: const TextStyle(fontSize: 16,
                                        fontWeight: FontWeight.w700, color: _green)),
                                const SizedBox(width: 12),
                                Text('-${(savings['money_som'] ?? savings['fuel_som'] ?? 0).toStringAsFixed(0)} сом',
                                    style: const TextStyle(fontSize: 16,
                                        fontWeight: FontWeight.w700, color: _green)),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (profile != null) ...[
                  const SizedBox(height: 12),
                  _buildStopsList(profile),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStopsList(Map<String, dynamic> profile) {
    final stops = profile['stops'] as List<dynamic>? ?? [];
    if (stops.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Остановки маршрута',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _stopRow(0, {'farm_name': _locationLabel, 'address': ''}, false),
          ...stops.asMap().entries.map((e) =>
              _stopRow(e.key + 1, e.value, e.key == stops.length - 1)),
        ],
      ),
    );
  }

  Widget _stopRow(int index, dynamic stop, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: index == 0 ? Colors.blue : _green,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: index == 0
                    ? const Icon(Icons.my_location, color: Colors.white, size: 14)
                    : Text('$index', style: const TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
            if (!isLast) Container(width: 2, height: 30, color: const Color(0xFFE0E0E0)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stop['farm_name'] ?? 'Ферма',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if ((stop['address'] ?? '').toString().isNotEmpty)
                  Text(stop['address'].toString(),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticInfo() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: _green, size: 48),
            SizedBox(height: 12),
            Text('Маршрут рассчитан', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Добавьте координаты фермы в профиле',
                style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                textAlign: TextAlign.center),
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF888888))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.route_outlined, color: _green, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Корзина пуста',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Добавьте товары чтобы построить маршрут',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 48),
            const SizedBox(height: 12),
            const Text('Не удалось загрузить маршрут',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_error, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRoute,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white),
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      ),
    );
  }
}