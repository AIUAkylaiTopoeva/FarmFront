import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';
import 'add_product_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF1C4A2A);
  static const _lightGreen = Color(0xFF81C784);

  List<dynamic> _myProducts = [];
  List<dynamic> _myOrders = [];
  bool _isProductsLoading = true;
  bool _isOrdersLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyProducts();
    _loadMyOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyProducts() async {
    setState(() => _isProductsLoading = true);
    try {
      final products = await ApiService.getMyProducts();
      if (mounted) setState(() { _myProducts = products; _isProductsLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isProductsLoading = false);
    }
  }

  Future<void> _loadMyOrders() async {
    setState(() => _isOrdersLoading = true);
    try {
      final orders = await ApiService.getFarmerOrders();
      if (mounted) setState(() { _myOrders = orders; _isOrdersLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isOrdersLoading = false);
    }
  }

  int get _ordersRevenue {
    int total = 0;
    for (final o in _myOrders) {
      if (o['status'] == 'done' || o['status'] == 'completed') {
        total += int.tryParse(o['total_price']?.toString() ?? '0') ?? 0;
      }
    }
    return total;
  }

  Future<void> _deleteProduct(int id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить товар?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Товар "$title" будет удалён навсегда.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteProduct(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Товар удалён'), backgroundColor: _green),
        );
      }
      _loadMyProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleProduct(int id, bool currentActive) async {
    try {
      await ApiService.updateProduct(id, isActive: !currentActive);
      _loadMyProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    try {
      await ApiService.updateOrderStatus(orderId, status);
      _loadMyOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditProductSheet(dynamic p) {
    final titleCtrl = TextEditingController(text: p['title'] ?? '');
    final priceCtrl = TextEditingController(text: p['price']?.toString() ?? '');
    final weightCtrl = TextEditingController(text: p['weight_kg']?.toString() ?? '');
    final descCtrl = TextEditingController(text: p['description'] ?? '');
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Редактировать товар',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _sheetField(titleCtrl, 'Название'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _sheetField(priceCtrl, 'Цена (сом)', keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _sheetField(weightCtrl, 'Вес (кг)', keyboard: TextInputType.number)),
              ]),
              const SizedBox(height: 10),
              _sheetField(descCtrl, 'Описание', maxLines: 3),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    setModalState(() => isLoading = true);
                    try {
                      await ApiService.updateProduct(
                        p['id'],
                        title: titleCtrl.text.trim(),
                        price: priceCtrl.text.trim(),
                        weightKg: weightCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadMyProducts();
                    } catch (e) {
                      setModalState(() => isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Сохранить изменения', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String hint,
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _green)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Шапка
            Container(
              color: _green,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Моя ферма',
                          style: TextStyle(color: _lightGreen, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(auth.email,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(children: [
                      Icon(Icons.agriculture, color: _lightGreen, size: 14),
                      SizedBox(width: 4),
                      Text('Фермер', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(50)),
                      child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Статистика
            Container(
              color: _green,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(child: _statCard('${_myProducts.length}', 'товаров', Icons.inventory_2_outlined, _green)),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard('${_myOrders.length}', 'заказов', Icons.receipt_long_outlined, Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard('$_ordersRevenue', 'сом', Icons.payments_outlined, Colors.orange)),
                ]),
              ),
            ),

            // Табы
            Container(
              color: const Color(0xFFF5F5F5),
              child: TabBar(
                controller: _tabController,
                labelColor: _green,
                unselectedLabelColor: const Color(0xFF888888),
                indicatorColor: _green,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: [
                  const Tab(text: 'Мои товары'),
                  Tab(text: 'Заказы (${_myOrders.length})'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductsTab(),
                  _buildOrdersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddProductScreen()));
          if (result == true) _loadMyProducts();
        },
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Добавить товар', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_isProductsLoading) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }
    if (_myProducts.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.add_box_outlined, color: _green, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('У вас пока нет товаров',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Нажмите кнопку ниже чтобы добавить',
              style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
        ]),
      );
    }
    return RefreshIndicator(
      color: _green,
      onRefresh: _loadMyProducts,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
        itemCount: _myProducts.length,
        itemBuilder: (context, index) {
          final p = _myProducts[index];
          return _farmerProductCard(p);
        },
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_isOrdersLoading) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }
    if (_myOrders.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.receipt_long_outlined, color: _green, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Заказов пока нет',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Новые заказы появятся здесь',
              style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
        ]),
      );
    }
    return RefreshIndicator(
      color: _green,
      onRefresh: _loadMyOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        itemCount: _myOrders.length,
        itemBuilder: (context, index) => _orderCard(_myOrders[index]),
      ),
    );
  }

  Widget _farmerProductCard(dynamic p) {
    final isActive = p['is_active'] == true;
    final imageUrl = p['image'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          // Фото
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl != null
                ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, __, _) => _productPlaceholder())
                : _productPlaceholder(),
          ),
          const SizedBox(width: 12),

          // Инфо
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['title'] ?? '',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${p['price']} сом · ${p['weight_kg'] ?? '—'} кг',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
              const SizedBox(height: 6),
              Row(children: [
                // Статус-переключатель
                GestureDetector(
                  onTap: () => _toggleProduct(p['id'], isActive),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(isActive ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 11, color: isActive ? _green : const Color(0xFFF57F17)),
                      const SizedBox(width: 3),
                      Text(isActive ? 'Активен' : 'Скрыт',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w500,
                              color: isActive ? _green : const Color(0xFFF57F17))),
                    ]),
                  ),
                ),
              ]),
            ]),
          ),

          // Кнопки действий
          Column(children: [
            GestureDetector(
              onTap: () => _showEditProductSheet(p),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit_outlined, color: _green, size: 16),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _deleteProduct(p['id'], p['title'] ?? ''),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline, color: Color(0xFFC62828), size: 16),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _orderCard(dynamic order) {
    final status = order['status'] ?? 'new';
    final (label, textColor, bgColor) = _statusInfo(status);
    final items = order['items'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Заказ #${order['id']}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(order['delivery_name'] ?? order['delivery_phone'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                Text(order['delivery_address'] ?? '',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
              child: Text(label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
            ),
          ]),
        ),

        if (items.isNotEmpty) ...[
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Column(
              children: items.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Icon(Icons.circle, size: 6, color: _green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item['product_title'] ?? 'Товар',
                      style: const TextStyle(fontSize: 12))),
                  Text('× ${item['quantity'] ?? 1}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                ]),
              )).toList(),
            ),
          ),
        ],

        // Кнопки смены статуса
        if (status == 'new' || status == 'pending') ...[
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateOrderStatus(order['id'], 'cancelled'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    side: const BorderSide(color: Color(0xFFFFCDD2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Отклонить', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateOrderStatus(order['id'], 'confirmed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                  child: const Text('Принять', style: TextStyle(fontSize: 12)),
                ),
              ),
            ]),
          ),
        ] else if (status == 'confirmed') ...[
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateOrderStatus(order['id'], 'delivering'),
                icon: const Icon(Icons.local_shipping_outlined, size: 16),
                label: const Text('Отправить', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ] else if (status == 'delivering') ...[
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateOrderStatus(order['id'], 'done'),
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('Доставлен', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  (String, Color, Color) _statusInfo(String status) {
    switch (status) {
      case 'confirmed': return ('Подтверждён', const Color(0xFF1565C0), const Color(0xFFE3F2FD));
      case 'delivering': return ('В пути', const Color(0xFFE65100), const Color(0xFFFFF3E0));
      case 'done':
      case 'completed': return ('Доставлен', const Color(0xFF1C4A2A), const Color(0xFFE8F5E9));
      case 'cancelled': return ('Отменён', const Color(0xFFC62828), const Color(0xFFFFEBEE));
      default: return ('Новый', const Color(0xFF555555), const Color(0xFFF5F5F5));
    }
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
      ]),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      width: 60, height: 60,
      color: const Color(0xFFE8F5E9),
      child: const Icon(Icons.eco_outlined, color: _green, size: 28),
    );
  }
}