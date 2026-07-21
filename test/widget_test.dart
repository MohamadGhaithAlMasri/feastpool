import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food/main.dart';
import 'package:food/features/auth/domain/entities/user.dart';
import 'package:food/features/auth/domain/repositories/auth_repository.dart';
import 'package:food/features/auth/presentation/bloc/auth_bloc.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  UserModel? get currentUser => null;

  @override
  Stream<UserModel?> get userStream => Stream.value(null);

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> signUp({required String email, required String password, required String name, required String department}) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> updateAvatar(String url) async {}

  @override
  Future<void> updateProfile({required String name, required String department}) async {}

  @override
  Future<void> uploadDeviceToken(String token, String platform) async {}

  @override
  Future<void> refreshUser() async {}
}

void main() {
  testWidgets('FeastPoolApp starts, shows splash, and navigates to login smoke test', (WidgetTester tester) async {
    final authRepository = FakeAuthRepository();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: authRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(authRepository)..add(AuthCheckRequested()),
            ),
          ],
          child: const FeastPoolApp(),
        ),
      ),
    );

    // Verify splash screen loading text
    expect(find.text('Initialising Ledger'), findsOneWidget);

    // Let the splash screen periodic timer finish loading (2.5 seconds)
    // Ticking 55 times with 50ms interval
    for (int i = 0; i < 55; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Pump any remaining transitions/animations
    await tester.pumpAndSettle();

    // Verify that we are on the login screen
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
