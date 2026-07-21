import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/clearance_request.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../auth/domain/entities/user.dart';

// --- Events ---
abstract class ClearanceEvent {}
class ClearanceLoadRequested extends ClearanceEvent {}
class ClearanceApproved extends ClearanceEvent {
  final String userId;
  final double amount;
  ClearanceApproved(this.userId, this.amount);
}
class ClearanceRejected extends ClearanceEvent {
  final String id;
  ClearanceRejected(this.id);
}
class ClearanceAdded extends ClearanceEvent {
  final ClearanceRequest request;
  ClearanceAdded(this.request);
}
class _ClearanceChanged extends ClearanceEvent {
  final List<ClearanceRequest> requests;
  _ClearanceChanged(this.requests);
}

// --- States ---
class ClearanceState {
  final List<ClearanceRequest> requests;
  final List<UserModel> outstandingUsers;
  final bool isLoading;

  ClearanceState({
    required this.requests,
    required this.outstandingUsers,
    this.isLoading = false,
  });
}

// --- Bloc ---
class ClearanceBloc extends Bloc<ClearanceEvent, ClearanceState> {
  final AdminRepository _adminRepository;
  StreamSubscription<List<ClearanceRequest>>? _clearanceSubscription;

  ClearanceBloc(this._adminRepository)
      : super(ClearanceState(requests: [], outstandingUsers: [])) {
    on<ClearanceLoadRequested>(_onClearanceLoadRequested);
    on<ClearanceApproved>(_onClearanceApproved);
    on<ClearanceRejected>(_onClearanceRejected);
    on<ClearanceAdded>(_onClearanceAdded);
    on<_ClearanceChanged>(_onClearanceChanged);

    _clearanceSubscription = _adminRepository.clearanceStream.listen(
      (reqs) {
        add(_ClearanceChanged(reqs));
      },
      onError: (error) {
        print('ClearanceBloc stream error: $error');
      },
    );
  }

  Future<void> _onClearanceLoadRequested(ClearanceLoadRequested event, Emitter<ClearanceState> emit) async {
    emit(ClearanceState(
      requests: state.requests,
      outstandingUsers: state.outstandingUsers,
      isLoading: true,
    ));
    await _adminRepository.syncClearanceRequests();
    final users = await _adminRepository.fetchOutstandingUsers();
    emit(ClearanceState(
      requests: _adminRepository.clearanceRequests,
      outstandingUsers: users,
      isLoading: false,
    ));
  }

  Future<void> _onClearanceApproved(ClearanceApproved event, Emitter<ClearanceState> emit) async {
    emit(ClearanceState(
      requests: state.requests,
      outstandingUsers: state.outstandingUsers,
      isLoading: true,
    ));
    try {
      await _adminRepository.clearUserBalance(event.userId, event.amount);
      final users = await _adminRepository.fetchOutstandingUsers();
      emit(ClearanceState(
        requests: state.requests,
        outstandingUsers: users,
        isLoading: false,
      ));
    } catch (_) {
      emit(ClearanceState(
        requests: state.requests,
        outstandingUsers: state.outstandingUsers,
        isLoading: false,
      ));
    }
  }

  Future<void> _onClearanceRejected(ClearanceRejected event, Emitter<ClearanceState> emit) async {
    try {
      await _adminRepository.rejectClearance(event.id);
    } catch (_) {}
  }

  Future<void> _onClearanceAdded(ClearanceAdded event, Emitter<ClearanceState> emit) async {
    try {
      await _adminRepository.addClearanceRequest(event.request);
    } catch (_) {}
  }

  void _onClearanceChanged(_ClearanceChanged event, Emitter<ClearanceState> emit) {
    emit(ClearanceState(
      requests: event.requests,
      outstandingUsers: state.outstandingUsers,
      isLoading: state.isLoading,
    ));
  }

  @override
  Future<void> close() {
    _clearanceSubscription?.cancel();
    return super.close();
  }
}
