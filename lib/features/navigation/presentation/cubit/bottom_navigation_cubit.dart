import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'bottom_navigation_state.dart';

enum UserRole { picker, driver, team_leader }

class BottomNavigationCubit extends Cubit<BottomNavigationState> {
  BottomNavigationCubit({UserRole role = UserRole.picker})
    : super(BottomNavigationState(currentIndex: 0, role: role));

  void changeTab(int index) {
    if (index >= 0 && index < 4) {
      emit(state.copyWith(currentIndex: index));
    }
  }

  void changeRole(UserRole role) {
    emit(state.copyWith(role: role, currentIndex: 0));
  }

  // Picker navigation methods
  void goToPickerOrders() => changeTab(0);
  void goToPickerReport() => changeTab(1);
  void goToProducts() => changeTab(2);
  void goToProfile() => changeTab(3);

  // Driver navigation methods
  void goToDriverOrders() => changeTab(0);
  void goToDriverReport() => changeTab(1);
  void goToDriverProducts() => changeTab(2);
  void goToDriverProfile() => changeTab(3);
}
