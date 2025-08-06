import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/bottom_navigation_cubit.dart';
import '../../../../core/di/injector.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../../../picker/presentation/pages/picker_orders_page.dart';
import '../../../picker/presentation/pages/picker_report_page.dart';
import '../../../driver/presentation/pages/driver_orders_page.dart';
import '../../../driver/presentation/pages/driver_report_page.dart';
import '../../../products/presentation/pages/products_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../picker/presentation/cubit/picker_orders_cubit.dart';

class RoleBasedNavigationPage extends StatelessWidget {
  final UserRole userRole;

  const RoleBasedNavigationPage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<BottomNavigationCubit>()..changeRole(userRole),
      child: _RoleBasedNavigationView(userRole: userRole),
    );
  }
}

class _RoleBasedNavigationView extends StatelessWidget {
  final UserRole userRole;

  const _RoleBasedNavigationView({required this.userRole});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavigationCubit, BottomNavigationState>(
      builder: (context, state) {
        return Scaffold(
          body: _buildBody(context, state.currentIndex),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: state.currentIndex,
            role: state.role,
            onTap: (index) {
              context.read<BottomNavigationCubit>().changeTab(index);
            },
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, int currentIndex) {
    // Team leaders should navigate like pickers
    final isPickerOrTeamLeader =
        userRole == UserRole.picker || userRole == UserRole.team_leader;

    switch (currentIndex) {
      case 0:
        return isPickerOrTeamLeader
            ? BlocProvider(
              create: (context) => getIt<PickerOrdersCubit>(),
              child: PickerOrdersPage(),
            )
            : DriverOrdersPage();
      case 1:
        return isPickerOrTeamLeader
            ? const PickerReportPage()
            : const DriverReportPage();
      case 2:
        return const ProductsPage();
      case 3:
        return const ProfilePage();
      default:
        return isPickerOrTeamLeader
            ? const PickerOrdersPage()
            : DriverOrdersPage();
    }
  }
}
