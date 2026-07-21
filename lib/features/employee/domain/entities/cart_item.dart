import 'meal.dart';

class CartItem {
  final Meal meal;
  final int quantity;

  CartItem({required this.meal, required this.quantity});

  CartItem copyWith({Meal? meal, int? quantity}) {
    return CartItem(
      meal: meal ?? this.meal,
      quantity: quantity ?? this.quantity,
    );
  }
}
