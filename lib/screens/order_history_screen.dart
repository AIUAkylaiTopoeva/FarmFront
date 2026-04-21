import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const _green = Color(0xFF1C4A2A);

  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await ApiService.getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить заказы';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('История заказов'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _orders.isEmpty
                  ? const Center(
                      child: Text(
                        'Пока нет заказов',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFF0F0F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Заказ #${order['id']}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Статус: ${order['status'] ?? 'new'}',
                                  style: const TextStyle(color: Color(0xFF555555)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Адрес: ${order['address'] ?? '—'}',
                                  style: const TextStyle(color: Color(0xFF888888)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Телефон: ${order['phone'] ?? '—'}',
                                  style: const TextStyle(color: Color(0xFF888888)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}