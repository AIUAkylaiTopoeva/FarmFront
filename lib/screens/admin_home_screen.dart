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

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const _green = Color(0xFF1C4A2A);
  // _lightGreen и _farmers убраны — не использовались

  List<dynamic> _products = [];
  bool _isLoading = true;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final products = await ApiService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1a1a1a),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Панель администратора',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1), // ← исправлено
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.admin_panel_settings,
                                color: Colors.amber, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Admin',
                              style: TextStyle(
                                  color: Colors.amber, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              color: const Color(0xFF1a1a1a),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        '${_products.length}',
                        'товаров',
                        Icons.inventory_2_outlined,
                        _green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        '0',
                        'фермеров',
                        Icons.agriculture_outlined,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        '0',
                        'заказов',
                        Icons.receipt_long_outlined,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1C4A2A)))
                  : _navIndex == 0
                      ? _buildProductsTab()
                      : _navIndex == 1
                          ? _buildFarmersTab()
                          : _buildSettingsTab(context, auth),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        selectedItemColor: _green,
        unselectedItemColor: const Color(0xFFAAAAAA),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2_rounded),
            label: 'Товары',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture_outlined),
            activeIcon: Icon(Icons.agriculture_rounded),
            label: 'Фермеры',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return const Center(
        child: Text(
          'Нет товаров',
          style: TextStyle(color: Color(0xFF888888)),
        ),
      );
    }
    return RefreshIndicator(
      color: _green,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final p = _products[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco_outlined,
                    color: Color(0xFF1C4A2A), size: 20),
              ),
              title: Text(
                p['title'] ?? '',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${p['owner_email'] ?? '—'} · ${p['price']} сом',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF888888)),
              ),
              trailing: Switch(
                value: p['is_active'] == true,
                onChanged: (_) {},
                activeThumbColor: _green, // ← исправлено
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFarmersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.agriculture_outlined,
                color: Color(0xFF1C4A2A), size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Список фермеров',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Здесь будет верификация фермеров',
            style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Color(0xFF1C4A2A)),
                  title: const Text('Роль',
                      style: TextStyle(fontSize: 13)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15), // ← исправлено
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Администратор',
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined,
                      color: Color(0xFF1C4A2A)),
                  title: const Text('Email',
                      style: TextStyle(fontSize: 13)),
                  trailing: Text(
                    auth.email,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Выйти из аккаунта'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
                side: const BorderSide(color: Color(0xFFFFCDD2)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}