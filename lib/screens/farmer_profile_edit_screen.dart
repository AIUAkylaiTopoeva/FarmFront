import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
    } catch (e) {
      // если профиль пустой, просто не заполняем
    }

    if (mounted) {
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _success = '';
    });

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
        setState(() {
          _success = 'Профиль обновлён';
        });
      } else {
        setState(() {
          _error = result.toString();
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка соединения';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _selectedPoint ?? _bishkek;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: _green,
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Профиль фермы',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isProfileLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _green),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _mapMode = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: !_mapMode
                                            ? _green
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 16,
                                            color: !_mapMode
                                                ? Colors.white
                                                : const Color(0xFF888888),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Ввести адрес',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: !_mapMode
                                                  ? Colors.white
                                                  : const Color(0xFF888888),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _mapMode = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _mapMode
                                            ? _green
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.map_outlined,
                                            size: 16,
                                            color: _mapMode
                                                ? Colors.white
                                                : const Color(0xFF888888),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Отметить на карте',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: _mapMode
                                                  ? Colors.white
                                                  : const Color(0xFF888888),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          _label('НАЗВАНИЕ ФЕРМЫ'),
                          const SizedBox(height: 6),
                          _input(
                            controller: _farmNameController,
                            hint: 'Ферма Айгуль',
                            icon: Icons.agriculture_outlined,
                          ),

                          const SizedBox(height: 14),

                          _label('АДРЕС'),
                          const SizedBox(height: 6),
                          _input(
                            controller: _addressController,
                            hint: 'Чуйская область, с. Кант',
                            icon: Icons.location_on_outlined,
                          ),

                          const SizedBox(height: 14),

                          if (!_mapMode) ...[
                            _label('КООРДИНАТЫ'),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _input(
                                    controller: _latController,
                                    hint: 'Широта (42.87)',
                                    icon: Icons.my_location,
                                    keyboard: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _input(
                                    controller: _lonController,
                                    hint: 'Долгота (74.59)',
                                    icon: Icons.my_location,
                                    keyboard: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            _label('ОТМЕТЬТЕ ФЕРМУ НА КАРТЕ'),
                            const SizedBox(height: 6),
                            Container(
                              height: 280,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
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
                                          _latController.text = point.latitude
                                              .toStringAsFixed(6);
                                          _lonController.text = point.longitude
                                              .toStringAsFixed(6);
                                        });
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.example.agro_app',
                                      ),
                                      if (_selectedPoint != null)
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: _selectedPoint!,
                                              width: 40,
                                              height: 40,
                                              child: const Icon(
                                                Icons.location_pin,
                                                color: _green,
                                                size: 40,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.touch_app_outlined,
                                            size: 14,
                                            color: _green,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Нажмите на карту чтобы отметить ферму',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF555555),
                                            ),
                                          ),
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
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: _green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Выбрано: ${_selectedPoint!.latitude.toStringAsFixed(4)}, ${_selectedPoint!.longitude.toStringAsFixed(4)}',
                                      style: const TextStyle(
                                        color: _green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
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
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFC62828),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error,
                                      style: const TextStyle(
                                        color: Color(0xFFC62828),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
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
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: _green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _success,
                                    style: const TextStyle(
                                      color: _green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Сохранить',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555),
          letterSpacing: 0.5,
        ),
      );

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
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFAAAAAA),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}