import 'package:flutter/material.dart';
import 'dart:developer';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/navigation/presentation/pages/role_based_navigation_page.dart';
import '../../features/navigation/presentation/cubit/bottom_navigation_cubit.dart';
import '../../features/picker/presentation/pages/item_listing_page.dart';
import '../../features/picker/data/models/order_item_model.dart';
import '../../features/picker/presentation/cubit/order_details_cubit.dart';
import '../services/user_storage_service.dart';
import '../pages/splash_page.dart';
import '../../features/picker/presentation/pages/item_add_page.dart';
import '../../features/picker/presentation/pages/order_item_details_page.dart';
import '../../features/picker/data/models/order_model.dart';
import 'package:flutter/foundation.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String itemListing = '/item-listing';
  static const String orderItemDetails = '/order-item-details';
  static const String itemAddPage = '/item_add_page';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (context) => const SplashPage());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (context) => const LoginPage());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (context) => const RegisterPage());
      case AppRoutes.home:
        // Get role from SharedPreferences with timeout
        return MaterialPageRoute(
          builder:
              (context) => FutureBuilder<UserRole?>(
                future: UserStorageService.getUserRole().timeout(
                  const Duration(seconds: 5),
                  onTimeout: () {
                    log("⚠️ User role retrieval timed out, using default role");
                    return UserRole.picker;
                  },
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final userRole = snapshot.data ?? UserRole.picker;
                  return RoleBasedNavigationPage(userRole: userRole);
                },
              ),
        );
      case AppRoutes.itemListing:
        // Handle both Map and List arguments for backward compatibility
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          List itemsRaw = args['items'] as List;
          List<OrderItemModel> items;
          if (itemsRaw.isNotEmpty && itemsRaw.first is OrderItemModel) {
            items = itemsRaw.cast<OrderItemModel>();
          } else {
            items =
                itemsRaw
                    .map(
                      (e) => OrderItemModel.fromJson(e as Map<String, dynamic>),
                    )
                    .toList();
          }
          return MaterialPageRoute(
            builder:
                (context) => ItemListingPage(
                  items: items,
                  title: args['title'] as String? ?? 'Item Listing',
                  cubit: args['cubit'] as OrderDetailsCubit?,
                  deliveryType: args['deliveryType'] as String?,
                  tabIndex: args['tabIndex'] as int?,
                  preparationId: args['preparationId'] as String? ?? '',
                  orderNumber: args['orderNumber'] as String? ?? '',
                  order: args['order'] as OrderModel,
                ),
          );
        } else if (settings.arguments is List<OrderItemModel>) {
          // Handle direct list of items (for backward compatibility)
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => ItemListingPage(
                  items: settings.arguments as List<OrderItemModel>,
                  title: 'Item Listing',
                  cubit: null,
                  preparationId: '',
                  orderNumber: '',
                  order: args['order'] as OrderModel,
                ),
          );
        } else {
          // Fallback for invalid arguments
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => ItemListingPage(
                  items: [],
                  title: 'Item Listing',
                  cubit: null,
                  preparationId: '',
                  orderNumber: '',
                  order: args['order'] as OrderModel,
                ),
          );
        }
      case AppRoutes.orderItemDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder:
              (context) => OrderItemDetailsPage(
                item: args['item'] as OrderItemModel,
                cubit: args['cubit'] as OrderDetailsCubit,
                preparationId: args['preparationId'] as String,
                order: args['order'] as OrderModel,
              ),
        );
      case AppRoutes.itemAddPage:
        final preparationId = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder:
              (context) => ItemAddPage(
                preparationId: preparationId['preparationId'] as String,
                cubit: preparationId['cubit'] as OrderDetailsCubit?,
                orderNumber: preparationId['orderNumber'] as String,
              ),
        );
      default:
        return MaterialPageRoute(builder: (context) => const SplashPage());
    }
  }
}
