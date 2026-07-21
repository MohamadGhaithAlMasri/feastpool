import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../admin/presentation/bloc/session_bloc.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/meal.dart';
import '../bloc/cart_bloc.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../../finance/presentation/bloc/ledger_bloc.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Future<List<Meal>> _mealsFuture;

  @override
  void initState() {
    super.initState();
    _mealsFuture = context.read<MenuRepository>().getMeals();
  }

  void _refreshMeals() {
    setState(() {
      _mealsFuture = context.read<MenuRepository>().getMeals();
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} Remaining';
  }
  void _showCartDialog(
    BuildContext context,
    double total,
    List<CartItem> cart,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24.0,
            16.0,
            24.0,
            MediaQuery.of(modalContext).viewInsets.bottom + 24.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(modalContext).size.height * 0.75,
            ),
            child: BlocBuilder<CartBloc, CartState>(
              bloc: context.read<CartBloc>(),
              builder: (context, state) {
                final cartItems = state.cartItems;
                final cartTotal = state.total;

                if (cartItems.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (modalContext.mounted) {
                      Navigator.pop(modalContext);
                    }
                  });
                  return const SizedBox.shrink();
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Confirm Order',
                          style: Theme.of(modalContext).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.meal.imageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 48,
                                      height: 48,
                                      color: AppColors.surface,
                                      child: const Icon(LucideIcons.image, size: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.meal.name,
                                        style: Theme.of(modalContext).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(item.meal.price * item.quantity).toStringAsFixed(0)} SYP',
                                        style: AppTheme.monoStyle(
                                          fontSize: 13,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        LucideIcons.minusCircle,
                                        color: AppColors.textSecondary,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        context.read<CartBloc>().add(
                                          CartItemQuantityDecreased(item.meal),
                                        );
                                      },
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: AppTheme.monoStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        LucideIcons.plusCircle,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        context.read<CartBloc>().add(
                                          CartItemAdded(item.meal),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        color: AppColors.danger,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        context.read<CartBloc>().add(
                                          CartItemRemoved(item.meal),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(color: AppColors.border, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: Theme.of(modalContext).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          '${cartTotal.toStringAsFixed(0)} SYP',
                          style: AppTheme.monoStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CartBloc>().add(CartCheckedOut(cartTotal));
                        Navigator.pop(modalContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Order placed successfully! Outstanding ledger updated.',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Place Order (Add to Ledger)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    UserModel? user;
    if (authState is Authenticated) {
      user = authState.user;
    }

    final sessionState = context.watch<SessionBloc>().state;
    final secondsRemaining = sessionState.secondsRemaining;
    final isSessionActive = sessionState.isActive;

    final cartState = context.watch<CartBloc>().state;
    final cart = cartState.cartItems;
    final cartTotal = cartState.total;

    return MultiBlocListener(
      listeners: [
        BlocListener<SessionBloc, SessionState>(
          listener: (context, state) {
            if (state.isActive &&
                state.category != null &&
                state.category != 'All') {
              final cartBloc = context.read<CartBloc>();
              final allowedCategories = state.category!
                  .split(',')
                  .map((c) => c.trim().toLowerCase())
                  .toList();
              final hasInvalidItems = cartBloc.state.cartItems.any(
                (item) =>
                    !allowedCategories.contains(item.meal.category.toLowerCase()),
              );
              if (hasInvalidItems) {
                cartBloc.add(CartCleared());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cart cleared: Session is restricted to category "${state.category}".',
                    ),
                    backgroundColor: AppColors.accentYellow,
                  ),
                );
              }
            }
          },
        ),
        BlocListener<CartBloc, CartState>(
          listenWhen: (previous, current) =>
              previous.cartItems.isNotEmpty && current.cartItems.isEmpty,
          listener: (context, state) {
            context.read<AuthBloc>().add(AuthCheckRequested());
            context.read<LedgerBloc>().add(LedgerLoadRequested());
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header (App Bar replacement matching design)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.surface,
                              backgroundImage:
                                  user?.avatarUrl != null &&
                                      user!.avatarUrl!.isNotEmpty
                                  ? NetworkImage(user.avatarUrl!)
                                  : (user?.role == UserRole.employee
                                            ? const NetworkImage(
                                                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                                              )
                                            : null)
                                        as ImageProvider?,
                              child:
                                  (user?.avatarUrl == null ||
                                          user!.avatarUrl!.isEmpty) &&
                                      user?.role != UserRole.employee
                                  ? const Icon(
                                      LucideIcons.user,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'FeastPool',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.bell,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  // Session Status Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: isSessionActive
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'ORDER WINDOW CLOSING',
                                  style: AppTheme.monoStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _formatDuration(secondsRemaining),
                                  style: AppTheme.monoStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: SizedBox(
                                    height: 4,
                                    child: LinearProgressIndicator(
                                      value:
                                          secondsRemaining /
                                          900.0, // Assuming 15min max session
                                      backgroundColor: AppColors.border,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            AppColors.primary,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.hourglass,
                                  color: AppColors.accentYellow,
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'ORDER WINDOW CLOSED',
                                  style: AppTheme.monoStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentYellow,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Waiting for admin to start a pool session...',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Daily Selection list title
                  FutureBuilder<List<Meal>>(
                    future: _mealsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              'Error loading meals: ${snapshot.error}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }
                      final meals = snapshot.data ?? [];
                      final filteredMeals =
                          (isSessionActive &&
                              sessionState.category != null &&
                              sessionState.category != 'All')
                          ? meals
                                .where(
                                  (meal) {
                                    final allowedCategories = sessionState.category!
                                        .split(',')
                                        .map((c) => c.trim().toLowerCase())
                                        .toList();
                                    return allowedCategories.contains(meal.category.toLowerCase());
                                  },
                                )
                                .toList()
                          : meals;

                      if (filteredMeals.isEmpty) {
                        return const Expanded(
                          child: Center(
                            child: Text(
                              'No meals available in the active category.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        );
                      }

                      final groupedMeals = <String, List<Meal>>{};
                      for (var meal in filteredMeals) {
                        groupedMeals
                            .putIfAbsent(meal.category, () => [])
                            .add(meal);
                      }
                      final categories = groupedMeals.keys.toList();

                      return Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      isSessionActive &&
                                              sessionState.category != null
                                          ? 'Daily Selection - ${sessionState.category}'
                                          : 'Daily Selection',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${filteredMeals.length} ITEMS AVAILABLE',
                                      style: AppTheme.monoStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  _refreshMeals();
                                },
                                color: AppColors.primary,
                                child: ListView.builder(
                                  padding: EdgeInsets.only(
                                    left: 20.0,
                                    right: 20.0,
                                    bottom: cart.isNotEmpty ? 100.0 : 20.0,
                                  ),
                                  itemCount: categories.length,
                                  itemBuilder: (context, catIndex) {
                                    final category = categories[catIndex];
                                    final categoryMeals =
                                        groupedMeals[category]!;

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                            top: 16,
                                            bottom: 8,
                                          ),
                                          child: Text(
                                            category.toUpperCase(),
                                            style: AppTheme.monoStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        ...categoryMeals.map((meal) {
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.cardBg,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                // Meal image
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.network(
                                                    meal.imageUrl,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, _, _) =>
                                                        Container(
                                                          width: 80,
                                                          height: 80,
                                                          color:
                                                              AppColors.surface,
                                                          child: const Icon(
                                                            LucideIcons.image,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                // Details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        meal.name,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        meal.description,
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.bodyMedium,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        '${meal.price.toStringAsFixed(0)} SYP',
                                                        style:
                                                            AppTheme.monoStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppColors
                                                                  .textPrimary,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Add button
                                                IconButton(
                                                  onPressed: isSessionActive
                                                      ? () {
                                                          context
                                                              .read<CartBloc>()
                                                              .add(
                                                                CartItemAdded(
                                                                  meal,
                                                                ),
                                                              );
                                                        }
                                                      : null,
                                                  icon: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: isSessionActive
                                                          ? AppColors.primary
                                                          : AppColors.border,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      LucideIcons.plus,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Persistent Cart summary footer
              if (cart.isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CART TOTAL',
                              style: AppTheme.monoStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${cartTotal.toStringAsFixed(0)} SYP',
                              style: AppTheme.monoStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _showCartDialog(context, cartTotal, cart),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirm Order',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
