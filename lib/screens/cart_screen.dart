import 'package:flutter/material.dart';
import '../services/cart_store.dart';
import 'route_screen.dart';
import 'order_create_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const _green = Color(0xFF1C4A2A);

  @override
  Widget build(BuildContext context) {
    final items = CartStore.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('Корзина'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Корзина пуста',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final qty = item['qty'] as int? ?? 1;
                final price = double.tryParse(item['price'].toString()) ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$price сом × $qty',
                              style: const TextStyle(
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(price * qty).toStringAsFixed(0)} сом',
                              style: const TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                CartStore.decrease(item['id']);
                              });
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$qty'),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                CartStore.increase(item['id']);
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Итого:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '${CartStore.total.toStringAsFixed(0)} сом',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _green,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RouteScreen(productIds: CartStore.productIds),
                              ),
                            );
                          },
                          icon: const Icon(Icons.route_outlined),
                          label: const Text('Маршрут'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrderCreateScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Оформить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}