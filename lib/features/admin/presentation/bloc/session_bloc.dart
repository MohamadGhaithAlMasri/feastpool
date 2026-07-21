import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_repository.dart';

// --- Events ---
abstract class SessionEvent {}
class SessionLoadRequested extends SessionEvent {}
class SessionStarted extends SessionEvent {
  final int durationSeconds;
  final String? category;
  SessionStarted(this.durationSeconds, {this.category});
}
class SessionStopped extends SessionEvent {}
class _SessionTimeChanged extends SessionEvent {
  final int secondsRemaining;
  _SessionTimeChanged(this.secondsRemaining);
}

// --- States ---
class SessionState {
  final int secondsRemaining;
  final bool isActive;
  final String? category;

  SessionState({required this.secondsRemaining, required this.isActive, this.category});
}

// --- Bloc ---
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final AdminRepository _adminRepository;
  StreamSubscription<int>? _sessionSubscription;

  SessionBloc(this._adminRepository) : super(SessionState(secondsRemaining: 0, isActive: false)) {
    on<SessionLoadRequested>(_onSessionLoadRequested);
    on<SessionStarted>(_onSessionStarted);
    on<SessionStopped>(_onSessionStopped);
    on<_SessionTimeChanged>(_onSessionTimeChanged);

    _sessionSubscription = _adminRepository.sessionStream.listen(
      (seconds) {
        add(_SessionTimeChanged(seconds));
      },
      onError: (error) {
        print('SessionBloc stream error: $error');
      },
    );
  }

  Future<void> _onSessionLoadRequested(SessionLoadRequested event, Emitter<SessionState> emit) async {
    await _adminRepository.syncSession();
    final seconds = _adminRepository.sessionTimeRemaining;
    emit(SessionState(
      secondsRemaining: seconds,
      isActive: seconds > 0,
      category: _adminRepository.sessionCategory,
    ));
  }

  Future<void> _onSessionStarted(SessionStarted event, Emitter<SessionState> emit) async {
    try {
      await _adminRepository.startSession(event.durationSeconds, category: event.category);
    } catch (e) {
      print('Error starting session: $e');
    }
  }

  Future<void> _onSessionStopped(SessionStopped event, Emitter<SessionState> emit) async {
    await _adminRepository.stopSession();
  }

  void _onSessionTimeChanged(_SessionTimeChanged event, Emitter<SessionState> emit) {
    emit(SessionState(
      secondsRemaining: event.secondsRemaining,
      isActive: event.secondsRemaining > 0,
      category: _adminRepository.sessionCategory,
    ));
  }

  @override
  Future<void> close() {
    _sessionSubscription?.cancel();
    return super.close();
  }
}
