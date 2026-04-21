import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'farmer_home_screen.dart';
import 'admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String _error = '';

  static const _green = Color(0xFF1C4A2A);
  static const _lightGreen = Color(0xFF81C784);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() => _error = 'Заполните все поля');
        return;
    }
    setState(() { _isLoading = true; _error = ''; });

    final success = await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
        final role = context.read<AuthProvider>().role;

        Widget nextScreen;
        if (role == 'farmer') {
        nextScreen = const FarmerHomeScreen();
        } else if (role == 'admin') {
        nextScreen = const AdminHomeScreen();
        } else {
        nextScreen = const HomeScreen();
        }

        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
        );
    } else {
        setState(() => _error = 'Неверный email или пароль');
    }
}

  void _goToRegister(String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterScreen(initialRole: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Шапка
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 36),
                decoration: const BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 42,
                        color: _green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AgroPath KG',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Фермер — покупатель. Напрямую.',
                      style: TextStyle(
                        color: _lightGreen,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Вход в аккаунт',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1a1a1a),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Введите ваши данные для входа',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email
                    const Text(
                      'EMAIL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF555555),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'example@mail.com',
                          hintStyle:
                              TextStyle(color: Color(0xFFBBBBBB)),
                          prefixIcon: Icon(Icons.email_outlined,
                              color: Color(0xFFAAAAAA), size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Пароль
                    const Text(
                      'ПАРОЛЬ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF555555),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        style: const TextStyle(fontSize: 14),
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle:
                              const TextStyle(color: Color(0xFFBBBBBB)),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Color(0xFFAAAAAA), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFFAAAAAA),
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),

                    // Ошибка
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFFFCDD2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFC62828), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error,
                                style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Кнопка войти
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Войти в аккаунт',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Разделитель
                    const Row(
                      children: [
                        Expanded(
                            child: Divider(color: Color(0xFFE0E0E0))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Нет аккаунта?',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFBBBBBB)),
                          ),
                        ),
                        Expanded(
                            child: Divider(color: Color(0xFFE0E0E0))),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Зарегистрироваться как
                    const Text(
                      'Зарегистрироваться как:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Карточки регистрации
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _goToRegister('farmer'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFE0E0E0)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.agriculture_outlined,
                                      color: _green,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Фермер',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1a1a1a),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Продаю продукты',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _goToRegister('customer'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFE0E0E0)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline_rounded,
                                      color: _green,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Покупатель',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1a1a1a),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Покупаю продукты',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }
}