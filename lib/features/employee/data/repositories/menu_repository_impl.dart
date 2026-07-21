import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/entities/meal.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  final sb.SupabaseClient _client;
  
  // Transient cart state managed locally in repository
  final List<CartItem> _cart = [];
  final StreamController<List<CartItem>> _cartController = StreamController<List<CartItem>>.broadcast();
  final StreamController<Map<String, dynamic>?> _activeOrderController = StreamController<Map<String, dynamic>?>.broadcast();
  StreamSubscription? _sessionSubscription;
  StreamSubscription? _transactionSubscription;

  MenuRepositoryImpl(this._client) {
    _cartController.add([]);
    _activeOrderController.add(null);
    _setupActiveOrderSync();
  }

  void _setupActiveOrderSync() {
    _client.auth.onAuthStateChange.listen((authState) {
      final session = authState.session;
      if (session != null) {
        _subscribeToActiveOrderUpdates();
      } else {
        _unsubscribeFromActiveOrderUpdates();
      }
    });

    if (_client.auth.currentUser != null) {
      _subscribeToActiveOrderUpdates();
    }
  }

  void _subscribeToActiveOrderUpdates() {
    _sessionSubscription?.cancel();
    _transactionSubscription?.cancel();

    fetchActiveOrder();

    _sessionSubscription = _client
        .from('pool_sessions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
          fetchActiveOrder();
        });

    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      _transactionSubscription = _client
          .from('ledger_transactions')
          .stream(primaryKey: ['id'])
          .eq('profile_id', userId)
          .listen((data) {
            fetchActiveOrder();
          });
    }
  }

  void _unsubscribeFromActiveOrderUpdates() {
    _sessionSubscription?.cancel();
    _sessionSubscription = null;
    _transactionSubscription?.cancel();
    _transactionSubscription = null;
    _activeOrderController.add(null);
  }

  @override
  Future<List<Meal>> getMeals() async {
    try {
      final res = await _client.from('meals').select();
      if (res.isEmpty) return [];
      return res.map((json) => Meal(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        imageUrl: json['image_url'] ?? '',
        category: json['category'] ?? 'General',
      )).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<CartItem>> get cartStream => _cartController.stream;

  @override
  List<CartItem> get cart => _cart;

  @override
  double get cartTotal => _cart.fold(0, (sum, item) => sum + (item.meal.price * item.quantity));

  @override
  Future<void> addToCart(Meal meal) async {
    final existingIndex = _cart.indexWhere((item) => item.meal.id == meal.id);
    if (existingIndex >= 0) {
      _cart[existingIndex] = _cart[existingIndex].copyWith(quantity: _cart[existingIndex].quantity + 1);
    } else {
      _cart.add(CartItem(meal: meal, quantity: 1));
    }
    _cartController.add(List.unmodifiable(_cart));
  }

  @override
  Future<void> decreaseQuantity(Meal meal) async {
    final existingIndex = _cart.indexWhere((item) => item.meal.id == meal.id);
    if (existingIndex >= 0) {
      if (_cart[existingIndex].quantity > 1) {
        _cart[existingIndex] = _cart[existingIndex].copyWith(quantity: _cart[existingIndex].quantity - 1);
      } else {
        _cart.removeAt(existingIndex);
      }
    }
    _cartController.add(List.unmodifiable(_cart));
  }

  @override
  Future<void> removeFromCart(Meal meal) async {
    _cart.removeWhere((item) => item.meal.id == meal.id);
    _cartController.add(List.unmodifiable(_cart));
  }

  @override
  Future<void> clearCart() async {
    _cart.clear();
    _cartController.add(List.unmodifiable(_cart));
  }

  @override
  Future<void> placeOrder(double total) async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      final itemsDescription = _cart.map((item) => "${item.quantity}x ${item.meal.name}").join(', ');

      // 1. Record the transaction in ledger_transactions
      try {
        await _client.from('ledger_transactions').insert({
          'profile_id': userId,
          'title': 'Pooled Meal Order: $itemsDescription',
          'amount': total,
          'status': 'UNPAID',
          'type': 'Lunch Pool',
        });
      } catch (e, stack) {
        debugPrint("Error inserting order transaction: $e\n$stack");
      }

      // 2. Try updating profile stats (ledger_balance, meals_ordered)
      try {
        final profile = await _client.from('profiles').select().eq('id', userId).single();
        final currentBalance = (profile['ledger_balance'] as num?)?.toDouble() ?? 0.0;
        final currentMeals = (profile['meals_ordered'] as int?) ?? 0;

        await _client.from('profiles').update({
          'ledger_balance': currentBalance + total,
          'meals_ordered': currentMeals + 1,
        }).eq('id', userId);
      } catch (e, stack) {
        debugPrint("Error updating profile balance: $e\n$stack");
      }
    }
    await clearCart();
    await fetchActiveOrder();
  }

  @override
  Future<void> addMeal(Meal meal) async {
    await _client.from('meals').insert({
      'name': meal.name,
      'description': meal.description,
      'price': meal.price,
      'image_url': meal.imageUrl,
      'category': meal.category,
    });
  }

  @override
  Future<void> updateMeal(Meal meal) async {
    final dynamic parsedId = int.tryParse(meal.id) ?? meal.id;
    await _client.from('meals').update({
      'name': meal.name,
      'description': meal.description,
      'price': meal.price,
      'image_url': meal.imageUrl,
      'category': meal.category,
    }).eq('id', parsedId);
  }

  @override
  Future<void> deleteMeal(String id) async {
    final dynamic parsedId = int.tryParse(id) ?? id;
    await _client.from('meals').delete().eq('id', parsedId);
  }

  @override
  Stream<Map<String, dynamic>?> get activeOrderStream => _activeOrderController.stream;

  @override
  Future<void> fetchActiveOrder() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _activeOrderController.add(null);
      return;
    }

    try {
      final sessionData = await _client
          .from('pool_sessions')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (sessionData == null || sessionData['status'] == 'ARRIVED') {
        _activeOrderController.add(null);
        return;
      }

      final sessionCreatedAt = DateTime.parse(sessionData['created_at']).toUtc();

      final transactionData = await _client
          .from('ledger_transactions')
          .select()
          .eq('profile_id', userId)
          .eq('type', 'Lunch Pool')
          .neq('status', 'CANCELLED')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (transactionData == null) {
        _activeOrderController.add(null);
        return;
      }

      final txCreatedAt = DateTime.parse(transactionData['created_at']).toUtc();
      if (txCreatedAt.isBefore(sessionCreatedAt)) {
        _activeOrderController.add(null);
        return;
      }

      final title = transactionData['title'] as String? ?? '';
      final Map<String, int> items = {};
      if (title.contains(':')) {
        final itemsPart = title.split(':').last.trim();
        final itemsList = itemsPart.split(',');
        for (var itemStr in itemsList) {
          final match = RegExp(r'(\d+)x\s+(.+)').firstMatch(itemStr.trim());
          if (match != null) {
            final qty = int.tryParse(match.group(1) ?? '1') ?? 1;
            final name = match.group(2)?.trim() ?? '';
            if (name.isNotEmpty) {
              items[name] = qty;
            }
          }
        }
      }

      _activeOrderController.add({
        'id': transactionData['id'].toString(),
        'items': items,
        'amount': (transactionData['amount'] as num).toDouble(),
        'status': transactionData['status'],
        'created_at': transactionData['created_at'],
      });
    } catch (e) {
      debugPrint('Error fetching active order: $e');
      _activeOrderController.add(null);
    }
  }

  @override
  Future<void> updateActiveOrder(String transactionId, Map<String, int> items, double newTotal) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final dynamic parsedId = int.tryParse(transactionId) ?? transactionId;
    final itemsDescription = items.entries
        .map((e) => "${e.value}x ${e.key}")
        .join(', ');

    try {
      final oldTx = await _client
          .from('ledger_transactions')
          .select('amount')
          .eq('id', parsedId)
          .single();
      final oldTotal = (oldTx['amount'] as num).toDouble();
      final difference = newTotal - oldTotal;

      await _client.from('ledger_transactions').update({
        'title': 'Pooled Meal Order: $itemsDescription',
        'amount': newTotal,
      }).eq('id', parsedId);

      final profile = await _client.from('profiles').select('ledger_balance').eq('id', userId).single();
      final currentBalance = (profile['ledger_balance'] as num?)?.toDouble() ?? 0.0;

      await _client.from('profiles').update({
        'ledger_balance': currentBalance + difference,
      }).eq('id', userId);

      await fetchActiveOrder();
    } catch (e) {
      debugPrint('Error updating active order: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteActiveOrder(String transactionId, double amount) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final dynamic parsedId = int.tryParse(transactionId) ?? transactionId;

    try {
      await _client.from('ledger_transactions').delete().eq('id', parsedId);

      final profile = await _client.from('profiles').select().eq('id', userId).single();
      final currentBalance = (profile['ledger_balance'] as num?)?.toDouble() ?? 0.0;
      final currentMeals = (profile['meals_ordered'] as int?) ?? 0;

      await _client.from('profiles').update({
        'ledger_balance': (currentBalance - amount).clamp(0.0, double.infinity),
        'meals_ordered': (currentMeals - 1).clamp(0, double.infinity),
      }).eq('id', userId);

      await fetchActiveOrder();
    } catch (e) {
      debugPrint('Error deleting active order: $e');
      rethrow;
    }
  }
}
