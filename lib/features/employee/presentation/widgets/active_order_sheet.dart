import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/bloc/session_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../finance/presentation/bloc/ledger_bloc.dart';
import '../../domain/entities/meal.dart';
import '../../domain/repositories/menu_repository.dart';
import '../bloc/active_order_bloc.dart';

class ActiveOrderSheet extends StatefulWidget {
  final Map<String, dynamic> activeOrder;

  const ActiveOrderSheet({super.key, required this.activeOrder});

  @override
  State<ActiveOrderSheet> createState() => _ActiveOrderSheetState();
}

class _ActiveOrderSheetState extends State<ActiveOrderSheet> {
  late Map<String, int> _editableItems;
  List<Meal>? _allMeals;
  bool _isLoadingMeals = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Clone the items map so we can edit it locally
    _editableItems = Map<String, int>.from(
      widget.activeOrder['items'] as Map<String, int>,
    );
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    try {
      final meals = await context.read<MenuRepository>().getMeals();
      if (mounted) {
        setState(() {
          _allMeals = meals;
          _isLoadingMeals = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMeals = false;
        });
      }
    }
  }

  Meal? _findMealByName(String name) {
    if (_allMeals == null) return null;
    return _allMeals!.firstWhere(
      (m) => m.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Meal(
        id: '',
        name: name,
        description: '',
        price: 0.0,
        imageUrl: '',
        category: '',
      ),
    );
  }

  double _calculateTotal() {
    double total = 0.0;
    _editableItems.forEach((name, qty) {
      final meal = _findMealByName(name);
      if (meal != null) {
        total += meal.price * qty;
      }
    });
    return total;
  }

  void _updateQuantity(String name, int delta) {
    setState(() {
      final currentQty = _editableItems[name] ?? 0;
      final newQty = currentQty + delta;
      if (newQty <= 0) {
        _editableItems.remove(name);
      } else {
        _editableItems[name] = newQty;
      }
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<SessionBloc>().state;
    final bool isSessionActive = sessionState.isActive;

    final totalAmount = _calculateTotal();
    final transactionId = widget.activeOrder['id'].toString();

    return BlocListener<ActiveOrderBloc, ActiveOrderState>(
      listener: (context, state) {
        if (state.status == ActiveOrderStatus.success) {
          context.read<AuthBloc>().add(AuthCheckRequested());
          context.read<LedgerBloc>().add(LedgerLoadRequested());
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state.status == ActiveOrderStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.errorMessage}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24.0,
          16.0,
          24.0,
          MediaQuery.of(context).viewInsets.bottom + 24.0,
        ),
        child: Column(
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
                  'My Active Order',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingMeals)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_editableItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    const Icon(
                      LucideIcons.shoppingBag,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No items in your order.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _editableItems.length,
                  itemBuilder: (context, index) {
                    final name = _editableItems.keys.elementAt(index);
                    final quantity = _editableItems[name]!;
                    final meal = _findMealByName(name);
                    final price = meal?.price ?? 0.0;

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
                          if (meal != null && meal.imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                meal.imageUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.surface,
                                  child: const Icon(
                                    LucideIcons.image,
                                    size: 20,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.utensils,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(price * quantity).toStringAsFixed(0)} SYP',
                                  style: AppTheme.monoStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSessionActive)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.minusCircle,
                                    color: AppColors.textSecondary,
                                    size: 22,
                                  ),
                                  onPressed: () => _updateQuantity(name, -1),
                                ),
                                Text(
                                  '$quantity',
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
                                  onPressed: () => _updateQuantity(name, 1),
                                ),
                              ],
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                'Qty: $quantity',
                                style: AppTheme.monoStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${totalAmount.toStringAsFixed(0)} SYP',
                  style: AppTheme.monoStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isSessionActive)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.lock,
                      color: AppColors.danger,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The order window is closed. You can no longer edit or cancel this order.',
                        style: TextStyle(
                          color: AppColors.danger.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              BlocBuilder<ActiveOrderBloc, ActiveOrderState>(
                builder: (context, activeOrderState) {
                  if (activeOrderState.status == ActiveOrderStatus.loading) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  if (_hasChanges && _editableItems.isNotEmpty) {
                    return ElevatedButton(
                      onPressed: () {
                        context.read<ActiveOrderBloc>().add(
                          UpdateActiveOrderRequested(
                            transactionId: transactionId,
                            items: _editableItems,
                            newTotal: totalAmount,
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
                        'Apply Changes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  return OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text(
                            'Delete Order',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Are you sure you want to cancel and delete your current order?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext); // Close dialog
                                context.read<ActiveOrderBloc>().add(
                                  DeleteActiveOrderRequested(
                                    transactionId: transactionId,
                                    amount: (widget.activeOrder['amount'] as num)
                                        .toDouble(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: AppColors.danger),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    label: const Text(
                      'Delete Order',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
