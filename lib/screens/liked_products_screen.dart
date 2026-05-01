import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';

class LikedProductsScreen extends StatefulWidget {
  const LikedProductsScreen({super.key});

  @override
  State<LikedProductsScreen> createState() => _LikedProductsScreenState();
}

class _LikedProductsScreenState extends State<LikedProductsScreen> {
  static const _green = Color(0xFF1C4A2A);
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final products = await ApiService.getLikedProducts();
      if (mounted) setState(() { _products = products; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('Понравившиеся'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _products.isEmpty
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.favorite_border, color: Color(0xFFCCCCCC), size: 64),
                    SizedBox(height: 16),
                    Text('Нет понравившихся товаров',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Text('Нажмите ❤️ на товаре чтобы добавить',
                        style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
                  ]),
                )
              : RefreshIndicator(
                  color: _green,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _products.length,
                    itemBuilder: (context, i) {
                      final p = _products[i];
                      final imageUrl = p['image'];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: p))),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF0F0F0)),
                          ),
                          child: Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: imageUrl != null
                                  ? Image.network(imageUrl, width: 64, height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _placeholder())
                                  : _placeholder(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['title'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(p['owner_email'] ?? 'Фермер',
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF888888))),
                                const SizedBox(height: 4),
                                Text('${p['price']} сом',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w700,
                                        color: _green)),
                              ],
                            )),
                            const Icon(Icons.favorite, color: Colors.red, size: 20),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _placeholder() {
    return Container(width: 64, height: 64, color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.eco_outlined, color: _green, size: 28));
  }
}