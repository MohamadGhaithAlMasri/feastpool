import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/image_uploader.dart';
import '../../../employee/domain/entities/meal.dart';
import '../bloc/admin_meals_bloc.dart';

class AdminMealsScreen extends StatelessWidget {
  const AdminMealsScreen({super.key});

  void _showMealForm(BuildContext context, {Meal? meal}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return MealFormDialog(meal: meal);
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Meal meal) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          title: const Text(
            'Delete Meal',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${meal.name}"? This action cannot be undone.',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                context.read<AdminMealsBloc>().add(DeleteAdminMeal(meal.id));
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Manage Meals',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(LucideIcons.plus),
        onPressed: () => _showMealForm(context),
      ),
      body: BlocBuilder<AdminMealsBloc, AdminMealsState>(
        builder: (context, state) {
          if (state is AdminMealsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          } else if (state is AdminMealsFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    color: AppColors.danger,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load meals: ${state.error}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<AdminMealsBloc>().add(LoadAdminMeals()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is AdminMealsLoaded) {
            final meals = state.meals;
            if (meals.isEmpty) {
              return const Center(
                child: Text(
                  'No meals found. Add your first meal!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            final groupedMeals = <String, List<Meal>>{};
            for (var meal in meals) {
              groupedMeals.putIfAbsent(meal.category, () => []).add(meal);
            }
            final categories = groupedMeals.keys.toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminMealsBloc>().add(LoadAdminMeals());
              },
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, catIndex) {
                  final category = categories[catIndex];
                  final categoryMeals = groupedMeals[category]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Image.network(
                                  meal.imageUrl,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 160,
                                      color: AppColors.cardBg,
                                      child: const Icon(
                                        LucideIcons.chefHat,
                                        size: 48,
                                        color: AppColors.textSecondary,
                                      ),
                                    );
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              meal.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${meal.price.toStringAsFixed(0)} SYP',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        meal.description,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _showMealForm(
                                              context,
                                              meal: meal,
                                            ),
                                            icon: const Icon(
                                              LucideIcons.edit2,
                                              size: 16,
                                              color: AppColors.primary,
                                            ),
                                            label: const Text(
                                              'Edit',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            onPressed: () =>
                                                _showDeleteConfirmation(
                                                  context,
                                                  meal,
                                                ),
                                            icon: const Icon(
                                              LucideIcons.trash2,
                                              size: 16,
                                              color: AppColors.danger,
                                            ),
                                            label: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: AppColors.danger,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      ),
    );
  }
}

class MealFormDialog extends StatefulWidget {
  final Meal? meal;
  const MealFormDialog({super.key, this.meal});

  @override
  State<MealFormDialog> createState() => _MealFormDialogState();
}

class _MealFormDialogState extends State<MealFormDialog> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController imageUrlController;
  late final TextEditingController categoryController;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.meal?.name ?? '');
    descriptionController = TextEditingController(
      text: widget.meal?.description ?? '',
    );
    priceController = TextEditingController(
      text: widget.meal?.price != null
          ? widget.meal!.price.toStringAsFixed(2)
          : '',
    );
    imageUrlController = TextEditingController(
      text: widget.meal?.imageUrl ?? '',
    );
    categoryController = TextEditingController(
      text: widget.meal?.category ?? 'General',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    imageUrlController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isUploading = true;
    });
    try {
      final url = await ImageUploader.uploadImage(
        bucketName: 'meals',
        pathPrefix: 'images',
      );
      if (url != null) {
        setState(() {
          imageUrlController.text = url;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload image: $e\nMake sure the public bucket "meals" exists in Supabase Storage.',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      title: Text(
        widget.meal == null ? 'Add New Meal' : 'Edit Meal',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrlController.text.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrlController.text,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadImage,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.image, size: 16),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Choose Image from Gallery',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Meal Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Price (SYP)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageUrlController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Category (e.g. Pastries, Sandwich)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            final name = nameController.text.trim();
            final description = descriptionController.text.trim();
            final price = double.tryParse(priceController.text.trim()) ?? 0.0;
            final imageUrl = imageUrlController.text.trim();
            final category = categoryController.text.trim().isEmpty
                ? 'General'
                : categoryController.text.trim();

            if (name.isEmpty || price <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please provide valid name and price'),
                ),
              );
              return;
            }

            if (widget.meal == null) {
              context.read<AdminMealsBloc>().add(
                AddAdminMeal(
                  Meal(
                    id: '',
                    name: name,
                    description: description,
                    price: price,
                    imageUrl: imageUrl,
                    category: category,
                  ),
                ),
              );
            } else {
              context.read<AdminMealsBloc>().add(
                UpdateAdminMeal(
                  Meal(
                    id: widget.meal!.id,
                    name: name,
                    description: description,
                    price: price,
                    imageUrl: imageUrl,
                    category: category,
                  ),
                ),
              );
            }
            Navigator.pop(context);
          },
          child: Text(widget.meal == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
