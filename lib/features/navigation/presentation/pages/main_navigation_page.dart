import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/bottom_navigation_cubit.dart';
import '../../../../core/di/injector.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../../../picker/presentation/pages/picker_orders_page.dart';
import '../../../picker/presentation/pages/picker_report_page.dart';
import '../../../driver/presentation/pages/driver_orders_page.dart';
import '../../../driver/presentation/pages/driver_report_page.dart';
import '../../../driver/presentation/pages/driver_bloc_wrapper.dart';
import '../../../products/presentation/pages/products_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../picker/presentation/cubit/picker_orders_cubit.dart';

class MainNavigationPage extends StatelessWidget {
  const MainNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<BottomNavigationCubit>(),
      child: const _MainNavigationView(),
    );
  }
}

class _MainNavigationView extends StatelessWidget {
  const _MainNavigationView();

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
    final role = context.read<BottomNavigationCubit>().state.role;

    switch (currentIndex) {
      case 0:
        return role == UserRole.picker
            ? BlocProvider(
                create: (context) => getIt<PickerOrdersCubit>(),
                child: const PickerOrdersPage(),
              )
            : DriverBlocWrapper(child: const DriverOrdersPage());
      case 1:
        return role == UserRole.picker
            ? const PickerReportPage()
            : DriverBlocWrapper(child: const DriverReportPage());
      case 2:
        return const ProductsPage();
      case 3:
        return const ProfilePage();
      default:
        return role == UserRole.picker
            ? BlocProvider(
                create: (context) => getIt<PickerOrdersCubit>(),
                child: const PickerOrdersPage(),
              )
            : DriverBlocWrapper(child: const DriverOrdersPage());
    }
  }
}
