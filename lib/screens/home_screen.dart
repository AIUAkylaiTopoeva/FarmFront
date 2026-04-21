import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/cart_store.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _green = Color(0xFF1C4A2A);

  List<dynamic> _products = [];
  List<dynamic> _filtered = [];
  List<String> _categories = ['Все'];

  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Все';
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      setState(() {
        _categories = ['Все', ...cats.map((c) => c['name'].toString())];
      });
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ApiService.getProducts();
      setState(() {
        _products = products;
        _filtered = products;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _filter(String query, String category) {
    setState(() {
      _searchQuery = query;
      _selectedCategory = category;
      _filtered = _products.where((p) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final categoryName = (p['category_name'] ?? '').toString();
        final matchQ = query.isEmpty || title.contains(query.toLowerCase());
        final matchC = category == 'Все' || categoryName == category;
        return matchQ && matchC;
      }).toList();
    });
  }

  void _toggleCart(dynamic product) {
    final id = product['id'] as int;
    setState(() {
      if (CartStore.contains(id)) {
        CartStore.remove(id);
      } else {
        CartStore.add(Map<String, dynamic>.from(product));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartIds = CartStore.productIds;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _buildHeader(),
                _buildCategories(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _green),
                        )
                      : _filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'Товары не найдены',
                                style: TextStyle(color: Color(0xFF888888)),
                              ),
                            )
                          : RefreshIndicator(
                              color: _green,
                              onRefresh: _loadProducts,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                                itemCount: _filtered.length,
                                itemBuilder: (context, index) {
                                  final p = _filtered[index];
                                  final isInCart = cartIds.contains(p['id']);
                                  return _productCard(p, isInCart);
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) async {
          if (i == 1) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
            setState(() => _navIndex = 0);
          } else if (i == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
            setState(() => _navIndex = 0);
          } else if (i == 3) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
            setState(() => _navIndex = 0);
          } else {
            setState(() => _navIndex = 0);
          }
        },
        selectedItemColor: _green,
        unselectedItemColor: const Color(0xFFAAAAAA),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag_rounded),
            label: 'Корзина',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            activeIcon: Icon(Icons.route_rounded),
            label: 'Маршрут',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _green,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Бишкек, Кыргызстан',
                    style: TextStyle(color: Color(0xFF81C784), fontSize: 11),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Добрый день!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (v) => _filter(v, _selectedCategory),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Поиск товаров и фермеров...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.white54, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      color: _green,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF6F7F8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: _categories.map((cat) {
              final sel = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => _filter(_searchQuery, cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? _green : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? _green : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : const Color(0xFF555555),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _productCard(dynamic p, bool isInCart) {
    final imageUrl = p['image'];
    final weight = p['weight_kg'];
    final weightStr = weight != null ? '$weight кг' : '—';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: p),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInCart ? const Color(0xFF1C4A2A) : const Color(0xFFEAEAEA),
            width: isInCart ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p['owner_email'] ?? 'Фермер'} · $weightStr',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _tag('Свежее', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                      _tag(
                        p['category_name'] ?? '',
                        const Color(0xFFF3E5F5),
                        const Color(0xFF6A1B9A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${p['price']} сом',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _toggleCart(p);
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isInCart ? const Color(0xFFE8F5E9) : _green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isInCart ? Icons.remove : Icons.add,
                  color: isInCart ? _green : Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.eco_outlined,
        color: _green,
        size: 34,
      ),
    );
  }
}