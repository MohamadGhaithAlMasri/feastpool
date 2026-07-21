import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

// --- Events ---
abstract class AuthEvent {}
class AuthCheckRequested extends AuthEvent {}
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested(this.email, this.password);
}
class AuthLogoutRequested extends AuthEvent {}
class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String department;
  AuthSignUpRequested({required this.email, required this.password, required this.name, required this.department});
}
class _AuthUserChanged extends AuthEvent {
  final UserModel? user;
  _AuthUserChanged(this.user);
}

// --- States ---
abstract class AuthState {}
class AuthInitial extends AuthState {}
class Authenticated extends AuthState {
  final UserModel user;
  Authenticated(this.user);
}
class Unauthenticated extends AuthState {}
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

// --- Bloc ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<UserModel?>? _userSubscription;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<_AuthUserChanged>(_onAuthUserChanged);

    // Subscribe to database changes
    _userSubscription = _authRepository.userStream.listen((user) {
      add(_AuthUserChanged(user));
    });
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    try {
      await _authRepository.refreshUser();
    } catch (_) {}
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    try {
      await _authRepository.login(event.email, event.password);
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthSignUpRequested(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    try {
      await _authRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        department: event.department,
      );
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
  }

  void _onAuthUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(Authenticated(event.user!));
    } else {
      emit(Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
