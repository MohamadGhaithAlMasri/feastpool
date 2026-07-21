import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final sb.SupabaseClient _client;
  final StreamController<UserModel?> _userController = StreamController<UserModel?>.broadcast();
  // ignore: unused_field
  StreamSubscription? _authSubscription;
  StreamSubscription? _profileSubscription;
  Timer? _profilePollTimer;
  UserModel? _cachedUser;

  AuthRepositoryImpl(this._client) {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user == null) {
        _profileSubscription?.cancel();
        _profileSubscription = null;
        _profilePollTimer?.cancel();
        _profilePollTimer = null;
        _cachedUser = null;
        _userController.add(null);
      } else {
        _subscribeToProfile(user);
        refreshUser();
        _startProfilePolling();
      }
    });

    final currentUser = _client.auth.currentUser;
    if (currentUser != null) {
      _subscribeToProfile(currentUser);
      refreshUser();
      _startProfilePolling();
    }
  }

  void _startProfilePolling() {
    _profilePollTimer?.cancel();
    _profilePollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_client.auth.currentUser != null) {
        refreshUser();
      }
    });
  }

  void _subscribeToProfile(sb.User user) {
    _profileSubscription?.cancel();
    _profileSubscription = _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .listen((data) {
          if (data.isNotEmpty) {
            final doc = data.first;
            final userModel = UserModel(
              id: doc['id'],
              name: doc['name'],
              email: doc['email'] ?? user.email ?? '',
              department: doc['department'],
              role: doc['role'] == 'admin' ? UserRole.admin : UserRole.employee,
              ledgerBalance: (doc['ledger_balance'] as num).toDouble(),
              mealsOrdered: doc['meals_ordered'] as int,
              avatarUrl: doc['avatar_url'],
            );
            _cachedUser = userModel;
            _userController.add(userModel);
          }
        }, onError: (err) {
          if (kDebugMode) {
            print('Error listening to user profile: $err');
          }
        });
  }

  @override
  Stream<UserModel?> get userStream => _userController.stream;

  @override
  UserModel? get currentUser {
    if (_cachedUser != null) return _cachedUser;
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return UserModel(
      id: user.id,
      name: user.userMetadata?['name'] ?? 'Ahmed Khalid',
      email: user.email ?? '',
      department: user.userMetadata?['department'] ?? 'عام',
      role: (user.email ?? '').contains('admin') ? UserRole.admin : UserRole.employee,
      ledgerBalance: 0.0,
      mealsOrdered: 0,
      avatarUrl: user.userMetadata?['avatar_url'],
    );
  }

  @override
  Future<void> login(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({required String email, required String password, required String name, required String department}) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'department': department,
      },
    );
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> updateAvatar(String url) async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await _client.from('profiles').update({'avatar_url': url}).eq('id', userId);
      // Also update auth user metadata so currentUser avatar gets updated immediately
      await _client.auth.updateUser(
        sb.UserAttributes(
          data: {'avatar_url': url},
        ),
      );
      await refreshUser();
    }
  }

  @override
  Future<void> updateProfile({required String name, required String department}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await _client.from('profiles').update({
        'name': name,
        'department': department,
      }).eq('id', userId);
      // Also update user metadata
      await _client.auth.updateUser(
        sb.UserAttributes(
          data: {
            'name': name,
            'department': department,
          },
        ),
      );
      await refreshUser();
    }
  }

  @override
  Future<void> refreshUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final doc = await _client.from('profiles').select().eq('id', userId).single();
        final userModel = UserModel(
          id: doc['id'],
          name: doc['name'],
          email: doc['email'] ?? _client.auth.currentUser?.email ?? '',
          department: doc['department'],
          role: doc['role'] == 'admin' ? UserRole.admin : UserRole.employee,
          ledgerBalance: (doc['ledger_balance'] as num).toDouble(),
          mealsOrdered: doc['meals_ordered'] as int,
          avatarUrl: doc['avatar_url'],
        );
        _cachedUser = userModel;
        _userController.add(userModel);
      } catch (e) {
        if (kDebugMode) {
          print('Error refreshing user profile: $e');
        }
      }
    }
  }

  @override
  Future<void> uploadDeviceToken(String token, String platform) async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _client.from('device_tokens').upsert({
          'user_id': userId,
          'token': token,
          'platform': platform,
        }, onConflict: 'token');
      } catch (e) {
        if (kDebugMode) {
          print('Error uploading device token to Supabase: $e');
        }
      }
    }
  }
}
