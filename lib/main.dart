import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/employee/data/repositories/menu_repository_impl.dart';
import 'features/employee/domain/repositories/menu_repository.dart';
import 'features/employee/presentation/bloc/cart_bloc.dart';
import 'features/employee/presentation/bloc/active_order_bloc.dart';
import 'features/finance/data/repositories/ledger_repository_impl.dart';
import 'features/finance/domain/repositories/ledger_repository.dart';
import 'features/finance/presentation/bloc/ledger_bloc.dart';
import 'features/admin/data/repositories/admin_repository_impl.dart';
import 'features/admin/domain/repositories/admin_repository.dart';
import 'features/admin/presentation/bloc/session_bloc.dart';
import 'features/admin/presentation/bloc/clearance_bloc.dart';
import 'features/admin/presentation/bloc/distribution_bloc.dart';
import 'features/admin/presentation/bloc/admin_meals_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lzwgrwwnpaumqvkproms.supabase.co',
    anonKey: 'sb_publishable_JZ5BMTpZseefwIiCSp5a3A_-zlnnqRu',
  );

  final client = Supabase.instance.client;

  // Instantiate repositories
  final authRepository = AuthRepositoryImpl(client);
  final menuRepository = MenuRepositoryImpl(client);
  final ledgerRepository = LedgerRepositoryImpl(client);
  final adminRepository = AdminRepositoryImpl(client);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<MenuRepository>.value(value: menuRepository),
        RepositoryProvider<LedgerRepository>.value(value: ledgerRepository),
        RepositoryProvider<AdminRepository>.value(value: adminRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authRepository)..add(AuthCheckRequested()),
          ),
          BlocProvider<CartBloc>(
            create: (context) =>
                CartBloc(menuRepository)..add(CartLoadRequested()),
          ),
          BlocProvider<SessionBloc>(
            create: (context) =>
                SessionBloc(adminRepository)..add(SessionLoadRequested()),
          ),
          BlocProvider<LedgerBloc>(
            create: (context) =>
                LedgerBloc(ledgerRepository)..add(LedgerLoadRequested()),
          ),
          BlocProvider<ClearanceBloc>(
            create: (context) =>
                ClearanceBloc(adminRepository)..add(ClearanceLoadRequested()),
          ),
          BlocProvider<DistributionBloc>(
            create: (context) =>
                DistributionBloc(adminRepository)
                  ..add(DistributionLoadRequested()),
          ),
          BlocProvider<AdminMealsBloc>(
            create: (context) =>
                AdminMealsBloc(menuRepository)..add(LoadAdminMeals()),
          ),
          BlocProvider<ActiveOrderBloc>(
            create: (context) =>
                ActiveOrderBloc(menuRepository)..add(ActiveOrderLoadRequested()),
          ),
        ],
        child: const FeastPoolApp(),
      ),
    ),
  );
}

class FeastPoolApp extends StatelessWidget {
  const FeastPoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FeastPool',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
