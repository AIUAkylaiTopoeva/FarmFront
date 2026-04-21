import 'package:flutter/material.dart';
import '../services/cart_store.dart';
import 'cart_screen.dart';
import 'route_screen.dart';
import 'order_create_screen.dart';

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({super.key});

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  static const _green = Color(0xFF1C4A2A);

  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _commentController = TextEditingController();

  String _error = '';
  String _success = '';

  void _submit() {
    if (_addressController.text.isEmpty || _phoneController.text.isEmpty) {
      setState(() {
        _error = 'Введите адрес и телефон';
        _success = '';
      });
      return;
    }

    setState(() {
      _error = '';
      _success = 'Заказ оформлен (демо-режим)';
    });

    CartStore.clear();
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
            _input(_addressController, 'Адрес доставки / самовывоза'),
            const SizedBox(height: 12),
            _input(_phoneController, 'Телефон'),
            const SizedBox(height: 12),
            _input(_commentController, 'Комментарий'),
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),
            if (_success.isNotEmpty)
              Text(_success, style: const TextStyle(color: _green)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Подтвердить заказ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
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