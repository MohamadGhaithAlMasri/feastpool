import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/distribution_item.dart';
import '../../domain/repositories/admin_repository.dart';

// --- Events ---
abstract class DistributionEvent {}
class DistributionLoadRequested extends DistributionEvent {}
class DistributionItemAdded extends DistributionEvent {
  final DistributionItem item;
  DistributionItemAdded(this.item);
}
class _DistributionChanged extends DistributionEvent {
  final List<DistributionItem> items;
  _DistributionChanged(this.items);
}

// --- States ---
class DistributionState {
  final List<DistributionItem> items;
  DistributionState({required this.items});
}

// --- Bloc ---
class DistributionBloc extends Bloc<DistributionEvent, DistributionState> {
  final AdminRepository _adminRepository;
  StreamSubscription<List<DistributionItem>>? _distributionSubscription;

  DistributionBloc(this._adminRepository) : super(DistributionState(items: [])) {
    on<DistributionLoadRequested>(_onDistributionLoadRequested);
    on<DistributionItemAdded>(_onDistributionItemAdded);
    on<_DistributionChanged>(_onDistributionChanged);

    _distributionSubscription = _adminRepository.distributionStream.listen(
      (items) {
        add(_DistributionChanged(items));
      },
      onError: (error) {
        print('DistributionBloc stream error: $error');
      },
    );
  }

  void _onDistributionLoadRequested(DistributionLoadRequested event, Emitter<DistributionState> emit) {
    emit(DistributionState(items: _adminRepository.distributionItems));
  }

  Future<void> _onDistributionItemAdded(DistributionItemAdded event, Emitter<DistributionState> emit) async {
    await _adminRepository.addDistributionItem(event.item);
  }

  void _onDistributionChanged(_DistributionChanged event, Emitter<DistributionState> emit) {
    emit(DistributionState(items: event.items));
  }

  @override
  Future<void> close() {
    _distributionSubscription?.cancel();
    return super.close();
  }
}
