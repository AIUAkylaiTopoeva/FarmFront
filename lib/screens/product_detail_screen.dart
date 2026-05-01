import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/cart_store.dart';
import 'route_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const _green = Color(0xFF1C4A2A);

  List<dynamic> _reviews = [];
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isReviewLoading = false;
  bool _reviewsLoaded = false;
  int _myRating = 5;
  final _reviewCtrl = TextEditingController();
  bool _showReviewForm = false;

  late bool _inCart;

  @override
  void initState() {
    super.initState();
    _inCart = CartStore.contains(widget.product['id'] as int);
    _likeCount = widget.product['likes_count'] ?? 0;
    _loadReviews();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews =
          await ApiService.getReviews(widget.product['id']);
      setState(() {
        _reviews = reviews;
        _reviewsLoaded = true;
      });
    } catch (_) {
      setState(() => _reviewsLoaded = true);
    }
  }

  Future<void> _toggleLike() async {
    setState(() => _isLiked = !_isLiked);
    try {
      final result =
          await ApiService.toggleLike(widget.product['id']);
      setState(() {
        _likeCount = result['likes_count'] ?? _likeCount;
      });
    } catch (_) {
      setState(() => _isLiked = !_isLiked);
    }
  }

  Future<void> _submitReview() async {
    if (_reviewCtrl.text.trim().isEmpty) return;
    setState(() => _isReviewLoading = true);
    try {
      await ApiService.addReview(
        widget.product['id'],
        _myRating,
        _reviewCtrl.text.trim(),
      );
      _reviewCtrl.clear();
      setState(() => _showReviewForm = false);
      await _loadReviews();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isReviewLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final imageUrl = p['image'];
    final title = p['title'] ?? 'Товар';
    final price = p['price'] ?? '—';
    final category = p['category_name'] ?? '';
    final owner = p['owner_email'] ?? 'Фермер';
    final description =
        p['description'] ?? 'Описание пока не добавлено.';
    final weight = p['weight_kg'] != null
        ? '${p['weight_kg']} кг'
        : '—';
    final quantity = p['quantity'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _)  =>
                          _placeholder(280),
                    )
                  : _placeholder(280),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color:
                      _isLiked ? Colors.red : Colors.white,
                ),
                onPressed: _toggleLike,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок + цена
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$_likeCount',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _reviews.isEmpty
                                      ? 'Нет отзывов'
                                      : '${(_reviews.fold<double>(0, (s, r) => s + (r['rating'] as num).toDouble()) / _reviews.length).toStringAsFixed(1)} (${_reviews.length})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$price сом',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Теги
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (category.isNotEmpty) _chip(category),
                      _chip(weight),
                      if (quantity != null)
                        _chip('В наличии: $quantity шт.'),
                      _chip('Свежее', color: _green),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Фермер
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFF0F0F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: const Icon(
                              Icons.agriculture_outlined,
                              color: _green,
                              size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Продавец',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              Text(
                                owner,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.verified_outlined,
                          color: _green,
                          size: 18,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Описание
                  const Text(
                    'Описание',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),

                  // Отзывы
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Отзывы (${_reviews.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(
                            () => _showReviewForm = !_showReviewForm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Text(
                            _showReviewForm
                                ? 'Отмена'
                                : '+ Отзыв',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_showReviewForm) ...[
                    const SizedBox(height: 12),
                    _buildReviewForm(),
                  ],

                  const SizedBox(height: 12),

                  if (!_reviewsLoaded)
                    const Center(
                      child: CircularProgressIndicator(
                          color: _green),
                    )
                  else if (_reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFF0F0F0)),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                color: Color(0xFFCCCCCC),
                                size: 32),
                            SizedBox(height: 8),
                            Text(
                              'Пока нет отзывов',
                              style: TextStyle(
                                  color: Color(0xFF888888)),
                            ),
                            Text(
                              'Будьте первым!',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._reviews
                        .take(5)
                        .map((r) => _reviewCard(r)),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteScreen(
                          productIds: [widget.product['id']]),
                    ),
                  );
                },
                icon: const Icon(Icons.route_outlined, size: 16),
                label: const Text('Маршрут'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  side: const BorderSide(color: _green),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    final id = widget.product['id'] as int;
                    if (CartStore.contains(id)) {
                      CartStore.remove(id);
                      _inCart = false;
                    } else {
                      CartStore.add(
                          Map<String, dynamic>.from(
                              widget.product));
                      _inCart = true;
                    }
                  });
                },
                icon: Icon(
                  _inCart ? Icons.check : Icons.shopping_bag_outlined,
                  size: 16,
                ),
                label: Text(
                    _inCart ? 'В корзине' : 'В корзину'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _inCart ? const Color(0xFF4CAF50) : _green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ваша оценка',
            style:
                TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () =>
                    setState(() => _myRating = i + 1),
                child: Icon(
                  i < _myRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reviewCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Напишите ваш отзыв...',
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isReviewLoading ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isReviewLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Отправить отзыв'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(dynamic r) {
    final rating = r['rating'] as int? ?? 5;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person,
                    color: _green, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r['user_email'] ?? 'Покупатель',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          if ((r['text'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r['text'],
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF555555),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text, {Color? color}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color != null
            ? color.withValues(alpha: 0.1)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? _green,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      child: const Icon(Icons.eco_outlined, color: _green, size: 64),
    );
  }
}