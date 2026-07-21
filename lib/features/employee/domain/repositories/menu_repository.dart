import '../entities/meal.dart';
import '../entities/cart_item.dart';

abstract class MenuRepository {
  Future<List<Meal>> getMeals();
  Stream<List<CartItem>> get cartStream;
  List<CartItem> get cart;
  double get cartTotal;
  Future<void> addToCart(Meal meal);
  Future<void> decreaseQuantity(Meal meal);
  Future<void> removeFromCart(Meal meal);
  Future<void> clearCart();
  Future<void> placeOrder(double total);
  Future<void> addMeal(Meal meal);
  Future<void> updateMeal(Meal meal);
  Future<void> deleteMeal(String id);

  // Active Order Management
  Stream<Map<String, dynamic>?> get activeOrderStream;
  Future<void> fetchActiveOrder();
  Future<void> updateActiveOrder(String transactionId, Map<String, int> items, double newTotal);
  Future<void> deleteActiveOrder(String transactionId, double amount);
}

