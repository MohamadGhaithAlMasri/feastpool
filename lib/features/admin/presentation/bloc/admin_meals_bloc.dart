import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../employee/domain/entities/meal.dart';
import '../../../employee/domain/repositories/menu_repository.dart';

// Events
abstract class AdminMealsEvent {}

class LoadAdminMeals extends AdminMealsEvent {}

class AddAdminMeal extends AdminMealsEvent {
  final Meal meal;
  AddAdminMeal(this.meal);
}

class UpdateAdminMeal extends AdminMealsEvent {
  final Meal meal;
  UpdateAdminMeal(this.meal);
}

class DeleteAdminMeal extends AdminMealsEvent {
  final String id;
  DeleteAdminMeal(this.id);
}

// States
abstract class AdminMealsState {}

class AdminMealsInitial extends AdminMealsState {}

class AdminMealsLoading extends AdminMealsState {}

class AdminMealsLoaded extends AdminMealsState {
  final List<Meal> meals;
  AdminMealsLoaded(this.meals);
}

class AdminMealsFailure extends AdminMealsState {
  final String error;
  AdminMealsFailure(this.error);
}

// BLoC
class AdminMealsBloc extends Bloc<AdminMealsEvent, AdminMealsState> {
  final MenuRepository _menuRepository;

  AdminMealsBloc(this._menuRepository) : super(AdminMealsInitial()) {
    on<LoadAdminMeals>(_onLoadAdminMeals);
    on<AddAdminMeal>(_onAddAdminMeal);
    on<UpdateAdminMeal>(_onUpdateAdminMeal);
    on<DeleteAdminMeal>(_onDeleteAdminMeal);
  }

  Future<void> _onLoadAdminMeals(LoadAdminMeals event, Emitter<AdminMealsState> emit) async {
    emit(AdminMealsLoading());
    try {
      final meals = await _menuRepository.getMeals();
      emit(AdminMealsLoaded(meals));
    } catch (e) {
      emit(AdminMealsFailure(e.toString()));
    }
  }

  Future<void> _onAddAdminMeal(AddAdminMeal event, Emitter<AdminMealsState> emit) async {
    emit(AdminMealsLoading());
    try {
      await _menuRepository.addMeal(event.meal);
      final meals = await _menuRepository.getMeals();
      emit(AdminMealsLoaded(meals));
    } catch (e) {
      emit(AdminMealsFailure(e.toString()));
    }
  }

  Future<void> _onUpdateAdminMeal(UpdateAdminMeal event, Emitter<AdminMealsState> emit) async {
    emit(AdminMealsLoading());
    try {
      await _menuRepository.updateMeal(event.meal);
      final meals = await _menuRepository.getMeals();
      emit(AdminMealsLoaded(meals));
    } catch (e) {
      emit(AdminMealsFailure(e.toString()));
    }
  }

  Future<void> _onDeleteAdminMeal(DeleteAdminMeal event, Emitter<AdminMealsState> emit) async {
    emit(AdminMealsLoading());
    try {
      await _menuRepository.deleteMeal(event.id);
      final meals = await _menuRepository.getMeals();
      emit(AdminMealsLoaded(meals));
    } catch (e) {
      emit(AdminMealsFailure(e.toString()));
    }
  }
}
