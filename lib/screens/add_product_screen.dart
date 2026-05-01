import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  bool _isLoading = false;
  bool _isInitLoading = true;
  String _error = '';
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  XFile? _pickedImage;
  List<int>? _pickedImageBytes;
  final _picker = ImagePicker();

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
      setState(() => _isInitLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = XFile(picked.path);
        _pickedImageBytes = null;
      });
      // Загружаем байты для отображения (работает и на вебе)
      final bytes = await picked.readAsBytes();
      setState(() => _pickedImageBytes = bytes);
    }
  }

  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Выберите источник фото',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _sourceBtn(
              Icons.photo_library_outlined,
              'Из галереи',
              () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            _sourceBtn(
              Icons.camera_alt_outlined,
              'Сделать фото',
              () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sourceBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _green, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty ||
        _priceController.text.isEmpty) {
      setState(() => _error = 'Введите название и цену');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      Map<String, dynamic> result;

      // Всегда используем multipart — работает и с фото и без
      result = await ApiService.createProductWithImage(
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
        imageXFile: _pickedImage,
        imageBytes: _pickedImageBytes,
      );

      if (result['id'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Товар успешно добавлен!'),
              backgroundColor: _green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() => _error = result.toString());
      }
    } catch (e) {
      setState(() => _error = 'Ошибка соединения: $e');
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
        elevation: 0,
      ),
      body: _isInitLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: _green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Фото-блок
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _pickedImage != null
                              ? _green
                              : const Color(0xFFCCCCCC),
                          width: _pickedImage != null ? 2 : 1,
                          style: _pickedImage != null
                              ? BorderStyle.solid
                              : BorderStyle.solid,
                        ),
                      ),
                      child: _pickedImage != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(15),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _pickedImageBytes != null
                                      ? Image.memory(
                                          Uint8List.fromList(_pickedImageBytes!),
                                          fit: BoxFit.cover,
                                        )
                                      : const SizedBox.shrink(),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                          _pickedImage = null;
                                          _pickedImageBytes = null;
                                        }),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(
                                                  alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 10,
                                            vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(
                                                  alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .edit_outlined,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Изменить',
                                              style: TextStyle(
                                                  color:
                                                      Colors.white,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color:
                                            const Color(0xFFCCCCCC)),
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: _green,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Добавить фото товара',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Из галереи или камеры',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888888)),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Основная информация'),
                  const SizedBox(height: 10),
                  _input(_titleController, 'Название товара',
                      icon: Icons.inventory_2_outlined),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _input(
                          _priceController,
                          'Цена (сом)',
                          keyboard: TextInputType.number,
                          icon: Icons.payments_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _input(
                          _weightController,
                          'Вес (кг)',
                          keyboard: TextInputType.number,
                          icon: Icons.scale_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _input(
                    _quantityController,
                    'Количество (шт.)',
                    keyboard: TextInputType.number,
                    icon: Icons.numbers_outlined,
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Категория'),
                  const SizedBox(height: 10),
                  _categoryDropdown(),

                  const SizedBox(height: 20),
                  _sectionLabel('Описание'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Расскажите о вашем товаре — сорт, условия выращивания...',
                      hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _green),
                      ),
                    ),
                  ),

                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 12),
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
                          Expanded(
                            child: Text(
                              _error,
                              style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontSize: 13),
                            ),
                          ),
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
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2),
                            )
                          : const Text(
                              'Опубликовать товар',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF555555),
      ),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedCategoryId,
      items: _categories
          .map((c) => DropdownMenuItem<int>(
                value: c['id'] as int,
                child: Text(c['name'].toString()),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedCategoryId = v),
      decoration: InputDecoration(
        hintText: 'Выберите категорию',
        prefixIcon: const Icon(Icons.category_outlined,
            color: Color(0xFF888888), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 13, color: Color(0xFF999999)),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF888888), size: 20)
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green),
        ),
      ),
    );
  }
}