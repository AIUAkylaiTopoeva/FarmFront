import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class RouteScreen extends StatefulWidget {
  final List<int> productIds;
  const RouteScreen({super.key, required this.productIds});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  Map<String, dynamic>? _result;
  bool _isLoading = true;
  String _error = '';
  String _selectedProfile = 'cheapest';

  // Контроллеры для полей топлива
  final _fuelPriceController = TextEditingController(text: '65');
  final _fuelConsumptionController = TextEditingController(text: '10');

  double get _fuelPrice =>
      double.tryParse(_fuelPriceController.text.replaceAll(',', '.')) ?? 65.0;
  double get _fuelConsumption =>
      double.tryParse(_fuelConsumptionController.text.replaceAll(',', '.')) ??
      10.0;

  static const _green = Color(0xFF1C4A2A);
  static const _lightGreen = Color(0xFF81C784);

  final double _userLat = 42.8746;
  final double _userLon = 74.5698;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _fuelPriceController.dispose();
    _fuelConsumptionController.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final result = await ApiService.compareRoutes(
        widget.productIds,
        _userLat,
        _userLon,
        fuelPrice: _fuelPrice,
        fuelConsumption: _fuelConsumption,
      );
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('2 distinct farmers')
            ? 'Нужно выбрать товары минимум от 2 разных фермеров'
            : 'Ошибка расчёта маршрута';
        _isLoading = false;
      });
    }
  }

  List<LatLng> _getRoutePoints() {
    if (_result == null || _result!['points'] == null) return [];
    final points = _result!['points'] as List;
    final List<LatLng> coords = [LatLng(_userLat, _userLon)];
    for (final p in points) {
      coords.add(LatLng(
        double.parse(p['lat'].toString()),
        double.parse(p['lon'].toString()),
      ));
    }
    return coords;
  }

  List<Marker> _getMarkers() {
    if (_result == null || _result!['points'] == null) return [];
    final points = _result!['points'] as List;
    final List<Marker> markers = [
      Marker(
        point: LatLng(_userLat, _userLon),
        width: 40,
        height: 40,
        child: const Icon(Icons.person_pin_circle,
            color: Colors.red, size: 40),
      ),
    ];
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      markers.add(
        Marker(
          point: LatLng(
            double.parse(p['lat'].toString()),
            double.parse(p['lon'].toString()),
          ),
          width: 80,
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.agriculture,
                  color: Color(0xFF1C4A2A), size: 32),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  p['farm_name'] != ''
                      ? p['farm_name']
                      : 'Ферма ${i + 1}',
                  style: const TextStyle(fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return markers;
  }

  Map<String, dynamic>? get _currentProfile =>
      _result?['profiles']?[_selectedProfile];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text(
          'Оптимальный маршрут',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1C4A2A)),
                  SizedBox(height: 16),
                  Text(
                    'Рассчитываем маршрут...',
                    style: TextStyle(color: Color(0xFF888888)),
                  ),
                ],
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFCCCCCC), size: 56),
                        const SizedBox(height: 16),
                        Text(
                          _error,
                          style: const TextStyle(
                              color: Color(0xFF555555),
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Добавьте товары от разных фермеров\nи попробуйте снова',
                          style: TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Вернуться'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Карта
                    SizedBox(
                      height: 240,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(_userLat, _userLon),
                          initialZoom: 11,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.example.agro_app',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _getRoutePoints(),
                                strokeWidth: 3.5,
                                color: _green,
                              ),
                            ],
                          ),
                          MarkerLayer(markers: _getMarkers()),
                        ],
                      ),
                    ),

                    // Результаты
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // ── Настройки топлива ──
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFF0F0F0)),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ПАРАМЕТРЫ ТОПЛИВА',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF555555),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              _fuelPriceController,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(
                                              decimal: true),
                                          decoration: InputDecoration(
                                            labelText: 'Цена сом/л',
                                            isDense: true,
                                            filled: true,
                                            fillColor: const Color(
                                                0xFFF9F9F9),
                                            border:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              _fuelConsumptionController,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(
                                              decimal: true),
                                          decoration: InputDecoration(
                                            labelText: 'Расход л/100км',
                                            isDense: true,
                                            filled: true,
                                            fillColor: const Color(
                                                0xFFF9F9F9),
                                            border:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 44,
                                        child: ElevatedButton(
                                          onPressed: _calculate,
                                          style:
                                              ElevatedButton.styleFrom(
                                            backgroundColor: _green,
                                            foregroundColor:
                                                Colors.white,
                                            shape:
                                                RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(10),
                                            ),
                                          ),
                                          child:
                                              const Text('ОК'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ── Профили ──
                            const Text(
                              'ПРОФИЛЬ МАРШРУТА',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF555555),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _profileCard(
                                    'cheapest',
                                    'Дешевле',
                                    Icons.savings_outlined,
                                    '${_result?['profiles']?['cheapest']?['fuel_cost_som']?.toStringAsFixed(0) ?? '—'} сом',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _profileCard(
                                    'fastest',
                                    'Быстрее',
                                    Icons.speed_outlined,
                                    '${_result?['profiles']?['fastest']?['travel_time_min']?.toStringAsFixed(0) ?? '—'} мин',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _profileCard(
                                    'balanced',
                                    'Баланс',
                                    Icons.balance_outlined,
                                    'оптим.',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // ── Детали текущего профиля ──
                            if (_currentProfile != null) ...[
                              const Text(
                                'ДЕТАЛИ МАРШРУТА',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _statCard(
                                      '${_currentProfile!['distance_km']?.toStringAsFixed(1) ?? '—'} км',
                                      'расстояние',
                                      Icons.route_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _statCard(
                                      '${_currentProfile!['fuel_used_l']?.toStringAsFixed(1) ?? '—'} л',
                                      'топливо',
                                      Icons.local_gas_station_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _statCard(
                                      '${_currentProfile!['travel_time_min']?.toStringAsFixed(0) ?? '—'} мин',
                                      'время',
                                      Icons.access_time_outlined,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Стоимость
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFF0F0F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                        Icons.local_gas_station,
                                        color: Color(0xFF1C4A2A),
                                        size: 22),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Стоимость топлива',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF888888)),
                                        ),
                                        Text(
                                          '${_currentProfile!['fuel_cost_som']?.toStringAsFixed(0) ?? '—'} сом',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1C4A2A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Цена бензина',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF888888)),
                                        ),
                                        Text(
                                          '${_fuelPrice.toStringAsFixed(0)} сом/л',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // ── Экономия ──
                              if (_result?['savings'] != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFA5D6A7)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.trending_down_rounded,
                                              color: Color(0xFF1C4A2A),
                                              size: 18),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Экономия vs наивного маршрута',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1C4A2A),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (_result!['savings']
                                                  ['money_pct'] !=
                                              null)
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 8,
                                                  vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                    0xFF1C4A2A),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(8),
                                              ),
                                              child: Text(
                                                '−${_result!['savings']['money_pct']}%',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _savingItem(
                                            '${_result!['savings']['money_som']?.toStringAsFixed(0) ?? '0'} сом',
                                            'деньги',
                                          ),
                                          Container(
                                              width: 1,
                                              height: 30,
                                              color: const Color(
                                                  0xFFA5D6A7)),
                                          _savingItem(
                                            '${_result!['savings']['time_min']?.toStringAsFixed(0) ?? '0'} мин',
                                            'время',
                                          ),
                                          Container(
                                              width: 1,
                                              height: 30,
                                              color: const Color(
                                                  0xFFA5D6A7)),
                                          _savingItem(
                                            '${_result!['savings']['distance_km']?.toStringAsFixed(1) ?? '0'} км',
                                            'расстояние',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 18),
                                  label: const Text(
                                    'Отлично, принято!',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _profileCard(
      String profile, String label, IconData icon, String value) {
    final isSelected = _selectedProfile == profile;
    return GestureDetector(
      onTap: () => setState(() => _selectedProfile = profile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? _green : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _green : const Color(0xFFE8E8E8),
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF888888),
                size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? _lightGreen
                    : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _green, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _savingItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C4A2A),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 10, color: Color(0xFF388E3C)),
        ),
      ],
    );
  }
}