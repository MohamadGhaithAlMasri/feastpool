import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/menu_repository.dart';

// --- Events ---
abstract class ActiveOrderEvent {}

class ActiveOrderLoadRequested extends ActiveOrderEvent {}

class _ActiveOrderChanged extends ActiveOrderEvent {
  final Map<String, dynamic>? activeOrder;
  _ActiveOrderChanged(this.activeOrder);
}

class UpdateActiveOrderRequested extends ActiveOrderEvent {
  final String transactionId;
  final Map<String, int> items;
  final double newTotal;
  UpdateActiveOrderRequested({
    required this.transactionId,
    required this.items,
    required this.newTotal,
  });
}

class DeleteActiveOrderRequested extends ActiveOrderEvent {
  final String transactionId;
  final double amount;
  DeleteActiveOrderRequested({
    required this.transactionId,
    required this.amount,
  });
}

enum ActiveOrderStatus { initial, loading, success, failure }

// --- States ---
class ActiveOrderState {
  final Map<String, dynamic>? activeOrder;
  final ActiveOrderStatus status;
  final String? errorMessage;

  ActiveOrderState({
    this.activeOrder,
    this.status = ActiveOrderStatus.initial,
    this.errorMessage,
  });

  ActiveOrderState copyWith({
    Map<String, dynamic>? activeOrder,
    ActiveOrderStatus? status,
    String? errorMessage,
  }) {
    return ActiveOrderState(
      activeOrder: activeOrder ?? this.activeOrder,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

// --- Bloc ---
class ActiveOrderBloc extends Bloc<ActiveOrderEvent, ActiveOrderState> {
  final MenuRepository _menuRepository;
  StreamSubscription<Map<String, dynamic>?>? _activeOrderSubscription;

  ActiveOrderBloc(this._menuRepository) : super(ActiveOrderState(status: ActiveOrderStatus.loading)) {
    on<ActiveOrderLoadRequested>(_onActiveOrderLoadRequested);
    on<_ActiveOrderChanged>(_onActiveOrderChanged);
    on<UpdateActiveOrderRequested>(_onUpdateActiveOrderRequested);
    on<DeleteActiveOrderRequested>(_onDeleteActiveOrderRequested);

    _activeOrderSubscription = _menuRepository.activeOrderStream.listen((activeOrder) {
      add(_ActiveOrderChanged(activeOrder));
    });
  }

  void _onActiveOrderLoadRequested(ActiveOrderLoadRequested event, Emitter<ActiveOrderState> emit) {
    emit(state.copyWith(status: ActiveOrderStatus.loading, errorMessage: null));
    _menuRepository.fetchActiveOrder();
  }

  void _onActiveOrderChanged(_ActiveOrderChanged event, Emitter<ActiveOrderState> emit) {
    emit(ActiveOrderState(activeOrder: event.activeOrder, status: ActiveOrderStatus.initial, errorMessage: null));
  }

  Future<void> _onUpdateActiveOrderRequested(UpdateActiveOrderRequested event, Emitter<ActiveOrderState> emit) async {
    emit(state.copyWith(status: ActiveOrderStatus.loading, errorMessage: null));
    try {
      await _menuRepository.updateActiveOrder(event.transactionId, event.items, event.newTotal);
      emit(state.copyWith(status: ActiveOrderStatus.success));
    } catch (e) {
      emit(state.copyWith(status: ActiveOrderStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteActiveOrderRequested(DeleteActiveOrderRequested event, Emitter<ActiveOrderState> emit) async {
    emit(state.copyWith(status: ActiveOrderStatus.loading, errorMessage: null));
    try {
      await _menuRepository.deleteActiveOrder(event.transactionId, event.amount);
      emit(state.copyWith(status: ActiveOrderStatus.success));
    } catch (e) {
      emit(state.copyWith(status: ActiveOrderStatus.failure, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _activeOrderSubscription?.cancel();
    return super.close();
  }
}
