import '../entities/user.dart';

abstract class AuthRepository {
  Stream<UserModel?> get userStream;
  UserModel? get currentUser;
  Future<void> login(String email, String password);
  Future<void> signUp({required String email, required String password, required String name, required String department});
  Future<void> logout();
  Future<void> updateAvatar(String url);
  Future<void> updateProfile({required String name, required String department});
  Future<void> uploadDeviceToken(String token, String platform);
  Future<void> refreshUser();
}
