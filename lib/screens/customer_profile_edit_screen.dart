import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CustomerProfileEditScreen extends StatefulWidget {
  const CustomerProfileEditScreen({super.key});

  @override
  State<CustomerProfileEditScreen> createState() =>
      _CustomerProfileEditScreenState();
}

class _CustomerProfileEditScreenState
    extends State<CustomerProfileEditScreen> {
  static const _green = Color(0xFF1C4A2A);

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String _error = '';
  String _success = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getMe();
      _nameController.text = data['first_name']?.toString() ?? '';
      _phoneController.text = data['phone']?.toString() ?? '';
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() { _isLoading = true; _error = ''; _success = ''; });
    try {
      await ApiService.updateProfile(
        firstName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) setState(() => _success = 'Профиль обновлён!');
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    }
    if (mounted) setState(() => _isLoading = false);
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
              color: _green,
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                      const Expanded(
                        child: Text('Мой профиль',
                            style: TextStyle(color: Colors.white,
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 10),
                  Text(auth.email,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Покупатель',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _label('ИМЯ'),
                    const SizedBox(height: 6),
                    _input(_nameController, 'Айгуль Токтосунова',
                        Icons.person_outline),

                    const SizedBox(height: 14),
                    _label('ТЕЛЕФОН'),
                    const SizedBox(height: 6),
                    _input(_phoneController, '+996 700 000 000',
                        Icons.phone_outlined,
                        keyboard: TextInputType.phone),

                    const SizedBox(height: 14),
                    _label('EMAIL'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              color: Color(0xFFAAAAAA), size: 20),
                          const SizedBox(width: 12),
                          Text(auth.email,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF888888))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Email нельзя изменить',
                        style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),

                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFC62828), size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error,
                                style: const TextStyle(
                                    color: Color(0xFFC62828), fontSize: 12))),
                          ],
                        ),
                      ),
                    ],

                    if (_success.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: _green, size: 16),
                            const SizedBox(width: 8),
                            Text(_success,
                                style: const TextStyle(
                                    color: _green, fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Сохранить',
                                style: TextStyle(fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: Color(0xFF555555), letterSpacing: 0.5));

  Widget _input(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
          prefixIcon: Icon(icon, color: const Color(0xFFAAAAAA), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}