import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/admin_meals_bloc.dart';
import '../bloc/distribution_bloc.dart';
import '../../domain/entities/distribution_item.dart';

class AddPersonScreen extends StatefulWidget {
  const AddPersonScreen({super.key});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final nameController = TextEditingController();
  final roomController = TextEditingController();
  final Map<String, int> selectedItems = {}; // mealName -> quantity

  @override
  void dispose() {
    nameController.dispose();
    roomController.dispose();
    super.dispose();
  }

  void _incrementQty(String mealName) {
    setState(() {
      selectedItems[mealName] = (selectedItems[mealName] ?? 0) + 1;
    });
  }

  void _decrementQty(String mealName) {
    setState(() {
      final current = selectedItems[mealName] ?? 0;
      if (current <= 1) {
        selectedItems.remove(mealName);
      } else {
        selectedItems[mealName] = current - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Add Person & Order',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Text info
                    Text(
                      'CUSTOMER INFO',
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: nameController,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: roomController,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Room/Department (e.g. ROOM 101)',
                              labelStyle: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Meals list header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SELECT MEALS',
                          style: AppTheme.monoStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedItems.isNotEmpty)
                          Text(
                            '${selectedItems.values.fold(0, (sum, q) => sum + q)} ITEMS SELECTED',
                            style: AppTheme.monoStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Meals list
                    BlocBuilder<AdminMealsBloc, AdminMealsState>(
                      builder: (context, state) {
                        if (state is AdminMealsLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }
                        if (state is AdminMealsFailure) {
                          return Center(
                            child: Text(
                              'Failed to load meals: ${state.error}',
                              style: const TextStyle(color: AppColors.danger),
                            ),
                          );
                        }
                        if (state is AdminMealsLoaded) {
                          final meals = state.meals;
                          if (meals.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Text(
                                  'No meals available. Add meals to the menu first!',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: meals.length,
                            itemBuilder: (context, index) {
                              final meal = meals[index];
                              final qty = selectedItems[meal.name] ?? 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        meal.imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 70,
                                                  height: 70,
                                                  color: AppColors.surface,
                                                  child: const Icon(
                                                    LucideIcons.image,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meal.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${meal.price.toStringAsFixed(0)} SYP',
                                            style: AppTheme.monoStyle(
                                              color: AppColors.primary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (qty > 0) ...[
                                          IconButton(
                                            onPressed: () =>
                                                _decrementQty(meal.name),
                                            icon: const Icon(
                                              LucideIcons.minusCircle,
                                              color: AppColors.textSecondary,
                                              size: 20,
                                            ),
                                          ),
                                          Text(
                                            qty.toString(),
                                            style: AppTheme.monoStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                        IconButton(
                                          onPressed: () =>
                                              _incrementQty(meal.name),
                                          icon: const Icon(
                                            LucideIcons.plusCircle,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final room = roomController.text.trim();

                  if (name.isEmpty || room.isEmpty || selectedItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter name, room, and select at least one meal!',
                        ),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }

                  context.read<DistributionBloc>().add(
                    DistributionItemAdded(
                      DistributionItem(
                        id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                        room: room,
                        userName: name,
                        items: Map<String, int>.from(selectedItems),
                      ),
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order added for $name!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add Order',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
