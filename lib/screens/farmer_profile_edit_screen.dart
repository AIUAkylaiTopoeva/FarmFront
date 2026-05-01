import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class FarmerProfileEditScreen extends StatefulWidget {
  const FarmerProfileEditScreen({super.key});

  @override
  State<FarmerProfileEditScreen> createState() =>
      _FarmerProfileEditScreenState();
}

class _FarmerProfileEditScreenState extends State<FarmerProfileEditScreen> {
  final _farmNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  static const _green = Color(0xFF1C4A2A);
  static const _bishkek = LatLng(42.8746, 74.5698);

  final MapController _mapController = MapController();

  LatLng? _selectedPoint;
  bool _isLoading = false;
  bool _isProfileLoading = true;
  bool _mapMode = false;
  String _error = '';
  String _success = '';

  // Для поиска адреса
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getFarmerProfile();
      _farmNameController.text = data['farm_name']?.toString() ?? '';
      _addressController.text = data['address']?.toString() ?? '';
      _latController.text = data['lat']?.toString() ?? '';
      _lonController.text = data['lon']?.toString() ?? '';

      if (data['lat'] != null && data['lon'] != null) {
        final lat = double.tryParse(data['lat'].toString());
        final lon = double.tryParse(data['lon'].toString());
        if (lat != null && lon != null) {
          _selectedPoint = LatLng(lat, lon);
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isProfileLoading = false);
  }

  // Поиск адреса через Nominatim (OpenStreetMap)
  Future<void> _searchAddress(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final encoded = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=5&countrycodes=kg&accept-language=ru',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'AgroPathKG/1.0',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _suggestions = data.map((item) => {
            'display_name': item['display_name'] as String,
            'lat': double.parse(item['lat'].toString()),
            'lon': double.parse(item['lon'].toString()),
          }).toList();
        });
      }
    } catch (_) {
      setState(() => _suggestions = []);
    }

    setState(() => _isSearching = false);
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final lat = suggestion['lat'] as double;
    final lon = suggestion['lon'] as double;
    final address = suggestion['display_name'] as String;

    setState(() {
      _selectedPoint = LatLng(lat, lon);
      _latController.text = lat.toStringAsFixed(6);
      _lonController.text = lon.toStringAsFixed(6);
      _addressController.text = address;
      _suggestions = [];
    });

    // Перемещаем карту к точке
    try {
      _mapController.move(LatLng(lat, lon), 14);
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() { _isLoading = true; _error = ''; _success = ''; });

    try {
      final lat = double.tryParse(_latController.text);
      final lon = double.tryParse(_lonController.text);

      final result = await ApiService.updateFarmerProfile(
        farmName: _farmNameController.text.trim(),
        address: _addressController.text.trim(),
        lat: lat,
        lon: lon,
      );

      if (result.containsKey('farm_name') || result.containsKey('lat')) {
        setState(() => _success = 'Профиль обновлён успешно!');
      } else {
        setState(() => _error = result.toString());
      }
    } catch (e) {
      setState(() => _error = 'Ошибка соединения');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _selectedPoint ?? _bishkek;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Шапка
            Container(
              color: _green,
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                  const Expanded(
                    child: Text('Профиль фермы',
                        style: TextStyle(color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isProfileLoading
                  ? const Center(child: CircularProgressIndicator(color: _green))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Переключатель режима
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _mapMode = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_mapMode ? _green : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.edit_outlined, size: 16,
                                              color: !_mapMode ? Colors.white : const Color(0xFF888888)),
                                          const SizedBox(width: 6),
                                          Text('Ввести адрес',
                                              style: TextStyle(fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: !_mapMode ? Colors.white : const Color(0xFF888888))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _mapMode = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _mapMode ? _green : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.map_outlined, size: 16,
                                              color: _mapMode ? Colors.white : const Color(0xFF888888)),
                                          const SizedBox(width: 6),
                                          Text('Отметить на карте',
                                              style: TextStyle(fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: _mapMode ? Colors.white : const Color(0xFF888888))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Название фермы
                          _label('НАЗВАНИЕ ФЕРМЫ'),
                          const SizedBox(height: 6),
                          _input(controller: _farmNameController,
                              hint: 'Ферма Айгуль', icon: Icons.agriculture_outlined),

                          const SizedBox(height: 14),

                          // Поиск адреса с автодополнением
                          _label('АДРЕС'),
                          const SizedBox(height: 6),
                          Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE0E0E0)),
                                ),
                                child: TextField(
                                  controller: _addressController,
                                  style: const TextStyle(fontSize: 14),
                                  onChanged: (v) => _searchAddress(v),
                                  decoration: InputDecoration(
                                    hintText: 'Начните вводить адрес...',
                                    hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                                    prefixIcon: const Icon(Icons.location_on_outlined,
                                        color: Color(0xFFAAAAAA), size: 20),
                                    suffixIcon: _isSearching
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: SizedBox(width: 16, height: 16,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2, color: _green)),
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 16),
                                  ),
                                ),
                              ),

                              // Подсказки адресов
                              if (_suggestions.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE0E0E0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 8, offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: _suggestions.asMap().entries.map((e) {
                                      final isLast = e.key == _suggestions.length - 1;
                                      return Column(
                                        children: [
                                          ListTile(
                                            dense: true,
                                            leading: const Icon(Icons.place_outlined,
                                                color: _green, size: 18),
                                            title: Text(
                                              e.value['display_name'] as String,
                                              style: const TextStyle(fontSize: 12),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            onTap: () => _selectSuggestion(e.value),
                                          ),
                                          if (!isLast)
                                            const Divider(height: 1,
                                                color: Color(0xFFF0F0F0)),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          if (!_mapMode) ...[
                            _label('КООРДИНАТЫ'),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _input(controller: _latController,
                                      hint: 'Широта (42.87)', icon: Icons.my_location,
                                      keyboard: TextInputType.number),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _input(controller: _lonController,
                                      hint: 'Долгота (74.59)', icon: Icons.my_location,
                                      keyboard: TextInputType.number),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Подсказка как найти координаты
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: _green, size: 14),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Или введите адрес выше — координаты заполнятся автоматически',
                                      style: TextStyle(fontSize: 11, color: _green),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            _label('ОТМЕТЬТЕ ФЕРМУ НА КАРТЕ'),
                            const SizedBox(height: 6),
                            Container(
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: initialCenter,
                                      initialZoom: 11,
                                      onTap: (_, point) {
                                        setState(() {
                                          _selectedPoint = point;
                                          _latController.text =
                                              point.latitude.toStringAsFixed(6);
                                          _lonController.text =
                                              point.longitude.toStringAsFixed(6);
                                        });
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'kg.agropath.app',
                                      ),
                                      if (_selectedPoint != null)
                                        MarkerLayer(markers: [
                                          Marker(
                                            point: _selectedPoint!,
                                            width: 40, height: 40,
                                            child: const Icon(Icons.location_pin,
                                                color: _green, size: 40),
                                          ),
                                        ]),
                                    ],
                                  ),
                                  Positioned(
                                    top: 10, left: 10, right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.touch_app_outlined,
                                              size: 14, color: _green),
                                          SizedBox(width: 6),
                                          Text('Нажмите на карту чтобы отметить ферму',
                                              style: TextStyle(fontSize: 11,
                                                  color: Color(0xFF555555))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedPoint != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        color: _green, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Выбрано: ${_selectedPoint!.latitude.toStringAsFixed(4)}, ${_selectedPoint!.longitude.toStringAsFixed(4)}',
                                      style: const TextStyle(color: _green, fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],

                          const SizedBox(height: 20),

                          if (_error.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Color(0xFFC62828), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_error,
                                      style: const TextStyle(color: Color(0xFFC62828),
                                          fontSize: 12))),
                                ],
                              ),
                            ),

                          if (_success.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      color: _green, size: 16),
                                  const SizedBox(width: 8),
                                  Text(_success, style: const TextStyle(color: _green,
                                      fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text('Сохранить',
                                      style: TextStyle(fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: Color(0xFF555555), letterSpacing: 0.5));

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
          prefixIcon: Icon(icon, color: const Color(0xFFAAAAAA), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}