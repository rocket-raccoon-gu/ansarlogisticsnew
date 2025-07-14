import '../../features/navigation/presentation/cubit/bottom_navigation_cubit.dart';

class RoleUtils {
  static UserRole getUserRoleFromApi(int roleId, String driverType) {
    // Map API role values to our UserRole enum
    // role 1 = picker, role 2 or 3 = driver
    switch (roleId) {
      case 1:
        return UserRole.picker;
      case 2:
      case 3:
        return UserRole.driver;
      default:
        // Fallback based on driverType field
        if (driverType.toLowerCase().contains('driver')) {
          return UserRole.driver;
        } else {
          return UserRole.picker;
        }
    }
  }

  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.picker:
        return 'Picker';
      case UserRole.driver:
        return 'Driver';
    }
  }

  static String getOrdersPageTitle(UserRole role) {
    switch (role) {
      case UserRole.picker:
        return 'Picker Orders';
      case UserRole.driver:
        return 'Driver Orders';
    }
  }

  static String getReportPageTitle(UserRole role) {
    switch (role) {
      case UserRole.picker:
        return 'Picker Report';
      case UserRole.driver:
        return 'Driver Report';
    }
  }
}
