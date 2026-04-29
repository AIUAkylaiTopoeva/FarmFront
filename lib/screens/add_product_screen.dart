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
  final _quantityController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isInitLoading = true;
  String _error = '';
  String _success = '';
  List<dynamic> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.getCategories();
      setState(() {
        _categories = categories;
        _isInitLoading = false;
      });
    } catch (_) {
      setState(() {
        _isInitLoading = false;
      });
    }
  }

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
        weightKg: _weightController.text.trim().isEmpty
            ? null
            : _weightController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        quantity: int.tryParse(_quantityController.text.trim()),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
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
        child: _isInitLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CircularProgressIndicator(color: _green),
                ),
              )
            : Column(
          children: [
            _input(_titleController, 'Название товара'),
            const SizedBox(height: 12),
            _input(_priceController, 'Цена (сом)', keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _input(_weightController, 'Вес (кг)', keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _input(_quantityController, 'Количество (шт.)',
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _categoryDropdown(),
            const SizedBox(height: 12),
            _input(_imageUrlController, 'URL картинки (опционально)'),
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

  Widget _categoryDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedCategoryId,
      items: _categories
          .map(
            (c) => DropdownMenuItem<int>(
              value: c['id'] as int,
              child: Text(c['name'].toString()),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedCategoryId = v),
      decoration: InputDecoration(
        hintText: 'Категория (опционально)',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
