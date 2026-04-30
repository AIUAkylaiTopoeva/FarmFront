import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/cart_store.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'route_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF1C4A2A);
  static const _lightGreen = Color(0xFF81C784);

  List<dynamic> _products = [];
  List<dynamic> _filtered = [];
  List<String> _categories = ['Все'];
  List<dynamic> _farmers = [];

  bool _isLoading = true;
  bool _isFarmersLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Все';
  int _navIndex = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _loadProducts();
    _loadFarmers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _loadFarmers() async {
    try {
      final farmers = await ApiService.getFarmersMap();
      setState(() {
        _farmers = farmers;
        _isFarmersLoading = false;
      });
    } catch (_) {
      setState(() => _isFarmersLoading = false);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Tabs
            Container(
              color: _green,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F7F8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: _green,
                  unselectedLabelColor: const Color(0xFF888888),
                  indicatorColor: _green,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Каталог'),
                    Tab(text: 'Карта ферм'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCatalogTab(),
                  _buildMapTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
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
                    style:
                        TextStyle(color: _lightGreen, fontSize: 11),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Добрый день! 🌿',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const CartScreen())),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  if (CartStore.count > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${CartStore.count}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen())),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (v) => _filter(v, _selectedCategory),
              style:
                  const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Поиск товаров...',
                hintStyle:
                    TextStyle(color: Colors.white54, fontSize: 13),
                prefixIcon: Icon(Icons.search,
                    color: Colors.white54, size: 18),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogTab() {
    return Column(
      children: [
        _buildCategories(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: _green))
              : _filtered.isEmpty
                  ? const Center(
                      child: Text('Товары не найдены',
                          style:
                              TextStyle(color: Color(0xFF888888))))
                  : RefreshIndicator(
                      color: _green,
                      onRefresh: _loadProducts,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            12, 8, 12, 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final p = _filtered[index];
                          final isInCart = CartStore.productIds
                              .contains(p['id']);
                          return _productCard(p, isInCart);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildMapTab() {
    // Центр Бишкека
    const bishkek = LatLng(42.8746, 74.5698);

    return _isFarmersLoading
        ? const Center(
            child: CircularProgressIndicator(color: _green))
        : Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: bishkek,
                  initialZoom: 11,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'kg.agropath.app',
                  ),
                  MarkerLayer(
                    markers: _farmers.map((f) {
                      final lat =
                          double.tryParse(f['lat'].toString());
                      final lon =
                          double.tryParse(f['lon'].toString());
                      if (lat == null || lon == null) {
                        return Marker(
                          point: bishkek,
                          child: const SizedBox.shrink(),
                        );
                      }
                      return Marker(
                        point: LatLng(lat, lon),
                        width: 160,
                        height: 70,
                        child: GestureDetector(
                          onTap: () =>
                              _showFarmerSheet(context, f),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _green,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  f['farm_name'] ??
                                      'Ферма',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: _green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.agriculture_outlined,
                          color: _green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Фермеров на карте: ${_farmers.length}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
  }

  void _showFarmerSheet(BuildContext context, dynamic farmer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.agriculture_outlined,
                      color: _green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmer['farm_name'] ?? 'Ферма',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        farmer['address'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(
                    '${farmer['products_count'] ?? 0} товаров',
                    Icons.inventory_2_outlined),
                const SizedBox(width: 8),
                _infoChip(
                    farmer['email'] ?? '',
                    Icons.email_outlined),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Фильтр по фермеру
                  setState(() {
                    _tabController.index = 0;
                    _filtered = _products
                        .where((p) =>
                            p['owner_email'] == farmer['email'])
                        .toList();
                  });
                },
                icon: const Icon(Icons.storefront_outlined,
                    size: 16),
                label: const Text('Смотреть товары'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String text, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _green),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
                fontSize: 11,
                color: _green,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _categories.map((cat) {
          final sel = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => _filter(_searchQuery, cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _green : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel
                      ? _green
                      : const Color(0xFFE0E0E0),
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel
                      ? Colors.white
                      : const Color(0xFF555555),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _productCard(dynamic p, bool isInCart) {
    final imageUrl = p['image'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: p),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInCart
                ? _green
                : const Color(0xFFEAEAEA),
            width: isInCart ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фото
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Stack(
                children: [
                  imageUrl != null
                      ? Image.network(
                          imageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, _) =>
                              _placeholder(130),
                        )
                      : _placeholder(130),
                  // Бейдж категории
                  if ((p['category_name'] ?? '').isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p['category_name'],
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),
                  // Кнопка корзины
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleCart(p),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isInCart
                              ? Colors.white
                              : _green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isInCart
                              ? Icons.check
                              : Icons.add,
                          color: isInCart
                              ? _green
                              : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Инфо
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.agriculture_outlined,
                          size: 10,
                          color: Color(0xFF888888)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          p['owner_email'] ?? 'Фермер',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF888888),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${p['price']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _green,
                        ),
                      ),
                      const Text(
                        ' сом',
                        style: TextStyle(
                          fontSize: 11,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      child: const Icon(Icons.eco_outlined,
          color: _green, size: 40),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) async {
        if (i == 1) {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CartScreen()));
          setState(() {});
        } else if (i == 2) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RouteScreen(productIds: CartStore.productIds),
            ),
          );
          setState(() => _navIndex = 0);
        } else if (i == 3) {
          await Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const ProfileScreen()));
          setState(() => _navIndex = 0);
        } else {
          setState(() => _navIndex = i);
        }
      },
      selectedItemColor: _green,
      unselectedItemColor: const Color(0xFFAAAAAA),
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Главная',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: CartStore.count > 0,
            label: Text('${CartStore.count}'),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          activeIcon: const Icon(Icons.shopping_bag_rounded),
          label: 'Корзина',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.route_outlined),
          activeIcon: Icon(Icons.route_rounded),
          label: 'Маршрут',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Профиль',
        ),
      ],
    );
  }
}