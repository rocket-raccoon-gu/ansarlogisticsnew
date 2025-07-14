part of 'bottom_navigation_cubit.dart';

class BottomNavigationState extends Equatable {
  final int currentIndex;
  final UserRole role;

  const BottomNavigationState({required this.currentIndex, required this.role});

  BottomNavigationState copyWith({int? currentIndex, UserRole? role}) {
    return BottomNavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [currentIndex, role];
}
