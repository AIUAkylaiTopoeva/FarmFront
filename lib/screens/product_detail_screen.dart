import 'package:flutter/material.dart';
import 'route_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  static const _green = Color(0xFF1C4A2A);

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['image'];
    final title = product['title'] ?? 'Товар';
    final price = product['price'] ?? '—';
    final category = product['category_name'] ?? '';
    final owner = product['owner_email'] ?? 'Фермер';
    final description = product['description'] ?? 'Описание пока не добавлено.';
    final weight = product['weight_kg'] != null ? '${product['weight_kg']} кг' : '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('Карточка товара'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '$price сом',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _chip(category.isEmpty ? 'Категория' : category),
                const SizedBox(width: 8),
                _chip(weight),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.agriculture_outlined, color: _green),
              title: const Text('Фермер'),
              subtitle: Text(owner),
            ),
            const SizedBox(height: 8),
            const Text(
              'Описание',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(color: Color(0xFF555555), height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteScreen(productIds: [product['id']]),
                    ),
                  );
                },
                icon: const Icon(Icons.route_outlined),
                label: const Text('Построить маршрут'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _green,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.eco_outlined, size: 64, color: _green),
    );
  }
}