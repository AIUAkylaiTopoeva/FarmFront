import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'farmer_profile_edit_screen.dart';
import 'order_history_screen.dart';
import 'home_screen.dart';
import 'farmer_home_screen.dart';
import 'admin_home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _green = Color(0xFF1C4A2A);
  static const _lightGreen = Color(0xFF81C784);

  void _goToRoleHome(BuildContext context, String role) {
    Widget nextScreen;

    if (role == 'farmer') {
      nextScreen = const FarmerHomeScreen();
    } else if (role == 'admin') {
      nextScreen = const AdminHomeScreen();
    } else {
      nextScreen = const HomeScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
      (_) => false,
    );
  }

  void _showRoleDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Сменить роль',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Выберите новую роль аккаунта',
              style: TextStyle(color: Color(0xFF888888), fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: auth.role == 'farmer'
                    ? null
                    : () async {
                        Navigator.pop(context);
                        final success = await auth.changeRole('farmer');
                        if (success && context.mounted) {
                          _goToRoleHome(context, 'farmer');
                        }
                      },
                icon: const Icon(Icons.agriculture_outlined, size: 18),
                label: Text(
                  auth.role == 'farmer' ? 'Фермер (текущая)' : 'Фермер',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: auth.role == 'customer'
                    ? null
                    : () async {
                        Navigator.pop(context);
                        final success = await auth.changeRole('customer');
                        if (success && context.mounted) {
                          _goToRoleHome(context, 'customer');
                        }
                      },
                icon: const Icon(Icons.person_outline, size: 18),
                label: Text(
                  auth.role == 'customer'
                      ? 'Покупатель (текущая)'
                      : 'Покупатель',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              color: _green,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Профиль',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: _lightGreen, width: 2),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    auth.email.isNotEmpty ? auth.email : 'Пользователь',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      auth.role == 'farmer'
                          ? 'Фермер'
                          : auth.role == 'admin'
                              ? 'Администратор'
                              : 'Покупатель',
                      style: const TextStyle(
                        color: _lightGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showRoleDialog(context, auth),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _lightGreen),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Сменить роль',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _menuSection([
                      _menuItem(
                        Icons.location_on_outlined,
                        auth.role == 'farmer' ? 'Профиль фермы' : 'Мой профиль',
                        auth.role == 'farmer'
                            ? 'Координаты и название фермы'
                            : 'Данные аккаунта',
                        onTap: () {
                          if (auth.role == 'farmer') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FarmerProfileEditScreen(),
                              ),
                            );
                          }
                        },
                      ),
                      _menuItem(
                        Icons.receipt_long_outlined,
                        'История заказов',
                        'Посмотреть мои заказы',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrderHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _menuSection([
                      _menuItem(
                        Icons.info_outline_rounded,
                        'О приложении',
                        'AgroPath KG MVP',
                      ),
                    ]),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuSection(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                const Divider(
                  height: 1,
                  color: Color(0xFFF5F5F5),
                  indent: 52,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _green, size: 17),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF888888),
              ),
            )
          : null,
      trailing: onTap != null
          ? const Icon(
              Icons.chevron_right,
              color: Color(0xFFAAAAAA),
              size: 18,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}