class CartStore {
  static final Map<int, Map<String, dynamic>> _items = {};

  static List<Map<String, dynamic>> get items => _items.values.toList();

  static int get count => _items.length;

  static bool contains(int productId) => _items.containsKey(productId);

  static void add(Map<String, dynamic> product) {
    final id = product['id'] as int;
    if (_items.containsKey(id)) {
      _items[id]!['qty'] = (_items[id]!['qty'] as int) + 1;
    } else {
      _items[id] = {
        ...product,
        'qty': 1,
      };
    }
  }

  static void remove(int productId) {
    _items.remove(productId);
  }

  static void increase(int productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!['qty'] = (_items[productId]!['qty'] as int) + 1;
    }
  }

  static void decrease(int productId) {
    if (_items.containsKey(productId)) {
      final current = _items[productId]!['qty'] as int;
      if (current > 1) {
        _items[productId]!['qty'] = current - 1;
      } else {
        _items.remove(productId);
      }
    }
  }

  static void clear() {
    _items.clear();
  }

  static List<int> get productIds => _items.keys.toList();

  static double get total {
    double sum = 0;
    for (final item in _items.values) {
      final price = double.tryParse(item['price'].toString()) ?? 0;
      final qty = item['qty'] as int? ?? 1;
      sum += price * qty;
    }
    return sum;
  }
}