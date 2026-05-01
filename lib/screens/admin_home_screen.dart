import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF1C4A2A);

  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  List<dynamic> _users = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getProducts(),
        ApiService.getAdminOrders(),
        ApiService.getAdminUsers(),
      ]);
      if (mounted) {
        setState(() {
          _products = results[0];
          _orders = results[1];
          _users = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _farmersCount => _users.where((u) => u['role'] == 'farmer').length;
  int get _customersCount => _users.where((u) => u['role'] == 'customer').length;
  int get _activeOrdersCount => _orders.where((o) =>
      o['status'] != 'done' && o['status'] != 'cancelled').length;

  Future<void> _toggleProduct(int id, bool current) async {
    try {
      await ApiService.adminToggleProduct(id, !current);
      _loadAll();
    } catch (_) {}
  }

  Future<void> _deleteProduct(int id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить товар?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Товар "$title" будет удалён.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteProduct(id);
      _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(int id, String status) async {
    try {
      await ApiService.updateOrderStatus(id, status);
      _loadAll();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(children: [
          // Шапка
          Container(
            color: const Color(0xFF1a1a1a),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Панель администратора',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                const SizedBox(height: 2),
                Text(auth.email,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(children: [
                  Icon(Icons.admin_panel_settings, color: Colors.amber, size: 14),
                  SizedBox(width: 4),
                  Text('Admin', style: TextStyle(color: Colors.amber, fontSize: 11)),
                ]),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ]),
          ),

          // Статистика
          Container(
            color: const Color(0xFF1a1a1a),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18), topRight: Radius.circular(18)),
              ),
              padding: const EdgeInsets.all(14),
              child: _isLoading
                  ? const SizedBox(height: 80,
                      child: Center(child: CircularProgressIndicator(color: _green)))
                  : Column(children: [
                      Row(children: [
                        Expanded(child: _statCard('${_products.length}', 'товаров',
                            Icons.inventory_2_outlined, _green)),
                        const SizedBox(width: 8),
                        Expanded(child: _statCard('$_farmersCount', 'фермеров',
                            Icons.agriculture_outlined, Colors.blue)),
                        const SizedBox(width: 8),
                        Expanded(child: _statCard('$_customersCount', 'покупателей',
                            Icons.people_outline, Colors.purple)),
                        const SizedBox(width: 8),
                        Expanded(child: _statCard('${_orders.length}', 'заказов',
                            Icons.receipt_long_outlined, Colors.orange)),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _statCard('$_activeOrdersCount', 'активных',
                            Icons.hourglass_empty, Colors.red)),
                        const SizedBox(width: 8),
                        Expanded(child: _statCard(
                            '${_orders.where((o) => o['status'] == 'done').length}',
                            'выполнено', Icons.done_all, const Color(0xFF1C4A2A))),
                        const SizedBox(width: 8),
                        Expanded(child: _statCard(
                            '${_users.length}', 'юзеров', Icons.group_outlined, Colors.teal)),
                        const SizedBox(width: 8),
                        Expanded(child: _statCard(
                            '${_products.where((p) => p['is_active'] == true).length}',
                            'активных', Icons.check_circle_outline, _green)),
                      ]),
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
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'Товары (${_products.length})'),
                Tab(text: 'Заказы (${_orders.length})'),
                Tab(text: 'Пользователи (${_users.length})'),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _green))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProductsTab(),
                      _buildOrdersTab(),
                      _buildUsersTab(context, auth),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return const Center(child: Text('Нет товаров',
          style: TextStyle(color: Color(0xFF888888))));
    }
    return RefreshIndicator(
      color: _green,
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        itemCount: _products.length,
        itemBuilder: (context, i) {
          final p = _products[i];
          final isActive = p['is_active'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10)),
                child: p['image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(p['image'], fit: BoxFit.cover,
                            errorBuilder: (_, __, _) =>
                                const Icon(Icons.eco_outlined, color: _green, size: 22)))
                    : const Icon(Icons.eco_outlined, color: _green, size: 22),
              ),
              title: Text(p['title'] ?? '',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text('${p['owner_email'] ?? '—'} · ${p['price']} сом',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Switch(
                  value: isActive,
                  onChanged: (_) => _toggleProduct(p['id'], isActive),
                  activeThumbColor: _green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                IconButton(
                  onPressed: () => _deleteProduct(p['id'], p['title'] ?? ''),
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return const Center(child: Text('Нет заказов',
          style: TextStyle(color: Color(0xFF888888))));
    }
    return RefreshIndicator(
      color: _green,
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        itemCount: _orders.length,
        itemBuilder: (context, i) {
          final o = _orders[i];
          final status = o['status'] ?? 'new';
          final (label, textColor, bgColor) = _statusInfo(status);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Заказ #${o['id']}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(o['delivery_name'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
                      Text(o['delivery_phone'] ?? '',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                      Text(o['delivery_address'] ?? '',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: bgColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(label,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              color: textColor)),
                    ),
                    if (o['total_price'] != null) ...[
                      const SizedBox(height: 6),
                      Text('${o['total_price']} сом',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: _green)),
                    ],
                  ]),
                ]),
              ),
              // Кнопки управления заказом
              if (status != 'done' && status != 'cancelled') ...[
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      if (status == 'new' || status == 'pending')
                        _statusBtn('Подтвердить', Colors.blue,
                            () => _updateOrderStatus(o['id'], 'confirmed')),
                      if (status == 'confirmed')
                        _statusBtn('В доставку', Colors.orange,
                            () => _updateOrderStatus(o['id'], 'delivering')),
                      if (status == 'delivering')
                        _statusBtn('Доставлен', _green,
                            () => _updateOrderStatus(o['id'], 'done')),
                      const SizedBox(width: 8),
                      _statusBtn('Отменить', const Color(0xFFC62828),
                          () => _updateOrderStatus(o['id'], 'cancelled')),
                    ]),
                  ),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }

  Widget _buildUsersTab(BuildContext context, AuthProvider auth) {
    return RefreshIndicator(
      color: _green,
      onRefresh: _loadAll,
      child: Column(children: [
        // Фильтр по ролям
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(children: [
            _roleChip('Все', _users.length),
            const SizedBox(width: 8),
            _roleChip('Фермеры', _farmersCount),
            const SizedBox(width: 8),
            _roleChip('Покупатели', _customersCount),
          ]),
        ),
        Expanded(
          child: _users.isEmpty
              ? const Center(child: Text('Нет пользователей',
                  style: TextStyle(color: Color(0xFF888888))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                  itemCount: _users.length,
                  itemBuilder: (context, i) {
                    final u = _users[i];
                    final role = u['role'] ?? 'customer';
                    final (roleLabel, roleColor) = _roleInfo(role);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              (u['email'] ?? 'U').substring(0, 1).toUpperCase(),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                  color: roleColor),
                            ),
                          ),
                        ),
                        title: Text(u['email'] ?? '',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: u['farm_name'] != null
                            ? Text(u['farm_name'], style: const TextStyle(fontSize: 11,
                                color: Color(0xFF888888)))
                            : null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(roleLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                  color: roleColor)),
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Выход
        Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false);
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Выйти из аккаунта'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
                side: const BorderSide(color: Color(0xFFFFCDD2)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _statusBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ),
    );
  }

  Widget _roleChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0))),
      child: Text('$label ($count)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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

  (String, Color) _roleInfo(String role) {
    switch (role) {
      case 'farmer': return ('Фермер', Colors.green);
      case 'admin': return ('Админ', Colors.amber.shade700);
      default: return ('Покупатель', Colors.blue);
    }
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF888888)),
            textAlign: TextAlign.center),
      ]),
    );
  }
}