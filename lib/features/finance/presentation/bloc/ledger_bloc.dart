import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/ledger_transaction.dart';
import '../../domain/repositories/ledger_repository.dart';

// --- Events ---
abstract class LedgerEvent {}
class LedgerLoadRequested extends LedgerEvent {}
class LedgerTransactionAdded extends LedgerEvent {
  final LedgerTransaction transaction;
  LedgerTransactionAdded(this.transaction);
}
class _LedgerChanged extends LedgerEvent {
  final List<LedgerTransaction> transactions;
  _LedgerChanged(this.transactions);
}

// --- States ---
class LedgerState {
  final List<LedgerTransaction> transactions;
  LedgerState({required this.transactions});
}

// --- Bloc ---
class LedgerBloc extends Bloc<LedgerEvent, LedgerState> {
  final LedgerRepository _ledgerRepository;
  StreamSubscription<List<LedgerTransaction>>? _ledgerSubscription;

  LedgerBloc(this._ledgerRepository) : super(LedgerState(transactions: [])) {
    on<LedgerLoadRequested>(_onLedgerLoadRequested);
    on<LedgerTransactionAdded>(_onLedgerTransactionAdded);
    on<_LedgerChanged>(_onLedgerChanged);

    _ledgerSubscription = _ledgerRepository.ledgerStream.listen(
      (txs) {
        add(_LedgerChanged(txs));
      },
      onError: (error) {
        print('LedgerBloc stream error: $error');
      },
    );
  }

  Future<void> _onLedgerLoadRequested(LedgerLoadRequested event, Emitter<LedgerState> emit) async {
    emit(LedgerState(transactions: _ledgerRepository.transactions));
    final txs = await _ledgerRepository.fetchTransactions();
    emit(LedgerState(transactions: txs));
  }

  Future<void> _onLedgerTransactionAdded(LedgerTransactionAdded event, Emitter<LedgerState> emit) async {
    await _ledgerRepository.addTransaction(event.transaction);
  }

  void _onLedgerChanged(_LedgerChanged event, Emitter<LedgerState> emit) {
    emit(LedgerState(transactions: event.transactions));
  }

  @override
  Future<void> close() {
    _ledgerSubscription?.cancel();
    return super.close();
  }
}
