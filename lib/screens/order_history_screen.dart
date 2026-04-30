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
    setState(() { _isLoading = true; _error = ''; });
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

  (String, Color, Color, IconData) _statusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return ('Подтверждён', const Color(0xFF1565C0),
            const Color(0xFFE3F2FD), Icons.check_circle_outline);
      case 'delivering':
        return ('В пути', const Color(0xFFE65100),
            const Color(0xFFFFF3E0), Icons.local_shipping_outlined);
      case 'done':
      case 'completed':
        return ('Доставлен', const Color(0xFF1C4A2A),
            const Color(0xFFE8F5E9), Icons.done_all_rounded);
      case 'cancelled':
        return ('Отменён', const Color(0xFFC62828),
            const Color(0xFFFFEBEE), Icons.cancel_outlined);
      default:
        return ('Новый', const Color(0xFF555555),
            const Color(0xFFF5F5F5), Icons.hourglass_empty_rounded);
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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _green))
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFCCCCCC), size: 48),
                      const SizedBox(height: 12),
                      Text(_error,
                          style: const TextStyle(
                              color: Color(0xFF888888))),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: const Icon(
                                Icons.receipt_long_outlined,
                                color: _green,
                                size: 40),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Заказов пока нет',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ваши заказы появятся здесь',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: _green,
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _orderCard(order);
                        },
                      ),
                    ),
    );
  }

  Widget _orderCard(dynamic order) {
    final status = order['status'] ?? 'new';
    final (label, textColor, bgColor, icon) = _statusInfo(status);
    final items = order['items'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          // Заголовок заказа
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                      Icons.receipt_long_outlined,
                      color: _green,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      if (order['created_at'] != null)
                        Text(
                          _formatDate(
                              order['created_at'].toString()),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888888),
                          ),
                        ),
                    ],
                  ),
                ),
                // Бейдж статуса
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: textColor),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Детали
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _detailRow(
                  Icons.location_on_outlined,
                  'Адрес',
                  order['delivery_address'] ??
                      order['address'] ??
                      '—',
                ),
                const SizedBox(height: 8),
                _detailRow(
                  Icons.phone_outlined,
                  'Телефон',
                  order['delivery_phone'] ??
                      order['phone'] ??
                      '—',
                ),
                if ((order['comment'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _detailRow(
                    Icons.comment_outlined,
                    'Комментарий',
                    order['comment'],
                  ),
                ],

                // Товары в заказе
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 10),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['product_title'] ??
                                    'Товар #${item['product']}',
                                style: const TextStyle(
                                    fontSize: 12),
                              ),
                            ),
                            Text(
                              '× ${item['quantity'] ?? 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],

                // Итого
                if (order['total_price'] != null) ...[
                  const Divider(height: 16, color: Color(0xFFF0F0F0)),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Итого:',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${order['total_price']} сом',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF888888)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF888888)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}