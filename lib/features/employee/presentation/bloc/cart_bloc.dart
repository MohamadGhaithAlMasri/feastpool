import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/meal.dart';
import '../../domain/repositories/menu_repository.dart';

// --- Events ---
abstract class CartEvent {}
class CartLoadRequested extends CartEvent {}
class CartItemAdded extends CartEvent {
  final Meal meal;
  CartItemAdded(this.meal);
}
class CartItemRemoved extends CartEvent {
  final Meal meal;
  CartItemRemoved(this.meal);
}
class CartItemQuantityDecreased extends CartEvent {
  final Meal meal;
  CartItemQuantityDecreased(this.meal);
}
class CartCleared extends CartEvent {}
class CartCheckedOut extends CartEvent {
  final double total;
  CartCheckedOut(this.total);
}
class _CartChanged extends CartEvent {
  final List<CartItem> cartItems;
  _CartChanged(this.cartItems);
}

// --- States ---
class CartState {
  final List<CartItem> cartItems;
  final double total;

  CartState({required this.cartItems, required this.total});

  CartState copyWith({List<CartItem>? cartItems, double? total}) {
    return CartState(
      cartItems: cartItems ?? this.cartItems,
      total: total ?? this.total,
    );
  }
}

// --- Bloc ---
class CartBloc extends Bloc<CartEvent, CartState> {
  final MenuRepository _menuRepository;
  StreamSubscription<List<CartItem>>? _cartSubscription;

  CartBloc(this._menuRepository) : super(CartState(cartItems: [], total: 0.0)) {
    on<CartLoadRequested>(_onCartLoadRequested);
    on<CartItemAdded>(_onCartItemAdded);
    on<CartItemRemoved>(_onCartItemRemoved);
    on<CartItemQuantityDecreased>(_onCartItemQuantityDecreased);
    on<CartCleared>(_onCartCleared);
    on<CartCheckedOut>(_onCartCheckedOut);
    on<_CartChanged>(_onCartChanged);

    _cartSubscription = _menuRepository.cartStream.listen((items) {
      add(_CartChanged(items));
    });
  }

  void _onCartLoadRequested(CartLoadRequested event, Emitter<CartState> emit) {
    emit(CartState(
      cartItems: _menuRepository.cart,
      total: _menuRepository.cartTotal,
    ));
  }

  Future<void> _onCartItemAdded(CartItemAdded event, Emitter<CartState> emit) async {
    await _menuRepository.addToCart(event.meal);
  }

  Future<void> _onCartItemRemoved(CartItemRemoved event, Emitter<CartState> emit) async {
    await _menuRepository.removeFromCart(event.meal);
  }

  Future<void> _onCartItemQuantityDecreased(CartItemQuantityDecreased event, Emitter<CartState> emit) async {
    await _menuRepository.decreaseQuantity(event.meal);
  }

  Future<void> _onCartCleared(CartCleared event, Emitter<CartState> emit) async {
    await _menuRepository.clearCart();
  }

  Future<void> _onCartCheckedOut(CartCheckedOut event, Emitter<CartState> emit) async {
    await _menuRepository.placeOrder(event.total);
  }

  void _onCartChanged(_CartChanged event, Emitter<CartState> emit) {
    emit(CartState(
      cartItems: event.cartItems,
      total: _menuRepository.cartTotal,
    ));
  }

  @override
  Future<void> close() {
    _cartSubscription?.cancel();
    return super.close();
  }
}
