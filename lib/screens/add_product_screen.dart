import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const _green = Color(0xFF1C4A2A);

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _weightController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  String _error = '';
  String _success = '';

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
      setState(() => _error = 'Введите название и цену');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _success = '';
    });

    try {
      final result = await ApiService.createProduct(
        title: _titleController.text.trim(),
        price: _priceController.text.trim(),
        weightKg: _weightController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (result['id'] != null) {
        setState(() => _success = 'Товар добавлен');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        setState(() => _error = result.toString());
      }
    } catch (e) {
      setState(() => _error = 'Ошибка соединения');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('Добавить товар'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _input(_titleController, 'Название товара'),
            const SizedBox(height: 12),
            _input(_priceController, 'Цена (сом)', keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _input(_weightController, 'Вес (кг)', keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _input(_descriptionController, 'Описание'),
            const SizedBox(height: 12),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),
            if (_success.isNotEmpty)
              Text(_success, style: const TextStyle(color: _green)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Сохранить'),
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