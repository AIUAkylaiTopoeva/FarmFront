import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final String initialRole;
  const RegisterScreen({super.key, this.initialRole = 'customer'});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  late String _role;
  bool _isLoading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String _error = '';

  static const _green = Color(0xFF1C4A2A);
  static const _lightGreen = Color(0xFF81C784);

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _farmNameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Валидация общих полей
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      setState(() => _error = 'Заполните все обязательные поля');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Пароль минимум 6 символов');
      return;
    }

    // Валидация полей фермера
    if (_role == 'farmer') {
      if (_farmNameController.text.isEmpty) {
        setState(() => _error = 'Введите название фермы');
        return;
      }
      if (_addressController.text.isEmpty) {
        setState(() => _error = 'Введите адрес фермы');
        return;
      }
      if (_latController.text.isEmpty || _lonController.text.isEmpty) {
        setState(() => _error = 'Введите координаты фермы');
        return;
      }
      if (double.tryParse(_latController.text) == null ||
          double.tryParse(_lonController.text) == null) {
        setState(() => _error = 'Координаты должны быть числами');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final data = await ApiService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _role,
      );

      if (mounted) {
        if (data.containsKey('email')) {
          // Если фермер — сразу сохраняем данные фермы
          if (_role == 'farmer') {
            final loginData = await ApiService.login(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
            if (loginData.containsKey('access')) {
              await ApiService.saveToken(loginData['access']);
              await ApiService.updateFarmerProfile(
                farmName: _farmNameController.text.trim(),
                address: _addressController.text.trim(),
                lat: double.tryParse(_latController.text),
                lon: double.tryParse(_lonController.text),
              );
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Аккаунт создан! Войдите в систему.'),
              backgroundColor: Color(0xFF1C4A2A),
            ),
          );
          Navigator.pop(context);
        } else {
          // Показываем ошибку от сервера
          final errorMsg = data.values.first;
          setState(() => _error = errorMsg is List
              ? errorMsg.first.toString()
              : errorMsg.toString());
        }
      }
    } catch (e) {
      setState(() => _error = 'Ошибка соединения с сервером');
    }

    setState(() => _isLoading = false);
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
                padding: const EdgeInsets.fromLTRB(8, 16, 24, 28),
                decoration: const BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Регистрация',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Создайте аккаунт для начала работы',
                            style: TextStyle(
                              color: _lightGreen,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),

                    // Выбор роли
                    _fieldLabel('КТО ВЫ?'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _role = 'customer'),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                color: _role == 'customer'
                                    ? _green
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                  color: _role == 'customer'
                                      ? _green
                                      : const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    color: _role == 'customer'
                                        ? Colors.white
                                        : const Color(0xFF888888),
                                    size: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Покупатель',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _role == 'customer'
                                          ? Colors.white
                                          : const Color(0xFF555555),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Покупаю продукты',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _role == 'customer'
                                          ? _lightGreen
                                          : const Color(0xFFAAAAAA),
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
                            onTap: () =>
                                setState(() => _role = 'farmer'),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                color: _role == 'farmer'
                                    ? _green
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                  color: _role == 'farmer'
                                      ? _green
                                      : const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.agriculture_outlined,
                                    color: _role == 'farmer'
                                        ? Colors.white
                                        : const Color(0xFF888888),
                                    size: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Фермер',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _role == 'farmer'
                                          ? Colors.white
                                          : const Color(0xFF555555),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Продаю продукты',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _role == 'farmer'
                                          ? _lightGreen
                                          : const Color(0xFFAAAAAA),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Email
                    _fieldLabel('EMAIL *'),
                    const SizedBox(height: 6),
                    _inputField(
                      controller: _emailController,
                      hint: 'example@mail.com',
                      icon: Icons.email_outlined,
                      keyboard: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 14),

                    // Пароль
                    _fieldLabel('ПАРОЛЬ *'),
                    const SizedBox(height: 6),
                    _inputField(
                      controller: _passwordController,
                      hint: 'Минимум 6 символов',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      onToggle: () =>
                          setState(() => _obscure = !_obscure),
                    ),

                    const SizedBox(height: 14),

                    // Подтверждение пароля
                    _fieldLabel('ПОДТВЕРДИТЕ ПАРОЛЬ *'),
                    const SizedBox(height: 6),
                    _inputField(
                      controller: _confirmController,
                      hint: 'Повторите пароль',
                      icon: Icons.lock_outline,
                      obscure: _obscureConfirm,
                      onToggle: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),

                    // Поля для фермера
                    if (_role == 'farmer') ...[
                      const SizedBox(height: 20),

                      // Разделитель
                      Row(
                        children: [
                          const Expanded(
                              child:
                                  Divider(color: Color(0xFFE0E0E0))),
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Данные фермы',
                              style: TextStyle(
                                fontSize: 11,
                                color: _green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Expanded(
                              child:
                                  Divider(color: Color(0xFFE0E0E0))),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Название фермы
                      _fieldLabel('НАЗВАНИЕ ФЕРМЫ *'),
                      const SizedBox(height: 6),
                      _inputField(
                        controller: _farmNameController,
                        hint: 'Ферма Айгуль',
                        icon: Icons.agriculture_outlined,
                      ),

                      const SizedBox(height: 14),

                      // Адрес
                      _fieldLabel('АДРЕС ФЕРМЫ *'),
                      const SizedBox(height: 6),
                      _inputField(
                        controller: _addressController,
                        hint: 'Чуйская область, с. Кант',
                        icon: Icons.location_on_outlined,
                      ),

                      const SizedBox(height: 14),

                      // Координаты
                      _fieldLabel('КООРДИНАТЫ ФЕРМЫ *'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: _green, size: 14),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Найдите координаты фермы на maps.google.com → нажмите на точку → скопируйте числа',
                                style: TextStyle(
                                    fontSize: 11, color: _green),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _inputField(
                              controller: _latController,
                              hint: 'Широта: 42.870',
                              icon: Icons.my_location,
                              keyboard: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _inputField(
                              controller: _lonController,
                              hint: 'Долгота: 74.590',
                              icon: Icons.my_location,
                              keyboard: TextInputType.number,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Уведомление о верификации
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFFFE082)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.verified_outlined,
                                color: Color(0xFFF57F17), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'После регистрации администратор проверит данные и верифицирует вашу ферму. Это занимает до 24 часов.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFF57F17),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Ошибка
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 14),
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
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Кнопка
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
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
                                'Создать аккаунт',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Уже есть аккаунт? Войти',
                          style: TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF555555),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool? obscure,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure ?? false,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFFBBBBBB)),
          prefixIcon: Icon(icon,
              color: const Color(0xFFAAAAAA), size: 20),
          suffixIcon: onToggle != null
              ? IconButton(
                  icon: Icon(
                    obscure == true
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFFAAAAAA),
                    size: 20,
                  ),
                  onPressed: onToggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}