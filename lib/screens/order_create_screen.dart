import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/cart_store.dart';

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({super.key});

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  static const _green = Color(0xFF1C4A2A);

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _commentController = TextEditingController();

  bool _isLoading = false;
  String _error = '';

  Future<void> _submit() async {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      setState(() => _error = 'Заполните имя, адрес и телефон');
      return;
    }

    setState(() { _isLoading = true; _error = ''; });

    try {
      final items = CartStore.items.map((item) => {
        'product': item['id'],
        'quantity': item['qty'] ?? 1,
      }).toList();

      await ApiService.createOrder(
        deliveryName: _nameController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        deliveryPhone: _phoneController.text.trim(),
        comment: _commentController.text.trim(),
        items: items,
      );

      CartStore.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заказ оформлен!'),
            backgroundColor: Color(0xFF1C4A2A),
          ),
        );
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('Оформление заказа'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _input(_nameController, 'Имя получателя'),
            const SizedBox(height: 12),
            _input(_addressController, 'Адрес доставки'),
            const SizedBox(height: 12),
            _input(_phoneController, 'Телефон',
                keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            _input(_commentController, 'Комментарий'),
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error,
                    style: const TextStyle(color: Color(0xFFC62828))),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Подтвердить заказ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}