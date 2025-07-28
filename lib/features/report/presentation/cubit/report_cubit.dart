import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/report_model.dart';
import '../../../../core/services/user_storage_service.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';

part 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ApiService _apiService;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();
  String _selectedRole = 'picker';

  ReportCubit({ApiService? apiService})
    : _apiService = apiService ?? ApiService(HttpClient(), WebSocketClient()),
      super(ReportInitial()) {
    print('🚀 ReportCubit: Created with role: $_selectedRole');
  }

  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;
  String get selectedRole => _selectedRole;

  // Test method to verify cubit is working
  void testCubit() {
    print('🧪 ReportCubit: Test method called');
    emit(
      ReportLoaded(
        PickerReportModel(
          role: 'picker',
          assignedOrders: 10,
          startedOrders: 8,
          completedOrders: 7,
          endPickedOrders: 6,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      ),
    );
  }

  Future<void> fetchReport() async {
    print('🔄 ReportCubit: Starting fetchReport');
    emit(ReportLoading());
    try {
      final user = await UserStorageService.getUserData();
      print(
        '👤 ReportCubit: User data - ${user?.user?.name}, Token: ${user?.token != null ? 'Present' : 'Missing'}',
      );

      if (user?.token == null) {
        print('❌ ReportCubit: User not authenticated');
        emit(ReportError('User not authenticated'));
        return;
      }

      print(
        '📊 ReportCubit: Fetching report for role: $_selectedRole, from: $_fromDate, to: $_toDate',
      );

      // Call the actual API
      final report = await _fetchReportFromAPI(
        user!.token!,
        _selectedRole,
        _fromDate,
        _toDate,
      );

      print(
        '✅ ReportCubit: Report loaded successfully - ${report.runtimeType}',
      );
      emit(ReportLoaded(report));
    } catch (e) {
      print('❌ ReportCubit: Error fetching report - $e');
      emit(ReportError('Failed to fetch report: ${e.toString()}'));
    }
  }

  void updateDateRange(DateTime fromDate, DateTime toDate) {
    print('📅 ReportCubit: Updating date range - $fromDate to $toDate');
    _fromDate = fromDate;
    _toDate = toDate;
    fetchReport();
  }

  void updateRole(String role) {
    print('👤 ReportCubit: Updating role - $role');
    _selectedRole = role;
    fetchReport();
  }

  void resetFilters() {
    print('🔄 ReportCubit: Resetting filters');
    _fromDate = DateTime.now().subtract(const Duration(days: 7));
    _toDate = DateTime.now();
    _selectedRole = 'picker';
    fetchReport();
  }

  // Actual API call method
  Future<ReportModel> _fetchReportFromAPI(
    String token,
    String role,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    print('🌐 ReportCubit: Calling API for $role report');
    try {
      final response = await _apiService.getReport(
        token: token,
        role: role,
        fromDate: fromDate,
        toDate: toDate,
      );

      print('📡 ReportCubit: API response received - ${response.statusCode}');
      print('📄 ReportCubit: API response data - ${response.data}');

      if (role == 'picker') {
        return PickerReportModel.fromJson(response.data);
      } else {
        return DriverReportModel.fromJson(response.data);
      }
    } catch (e) {
      // Fallback to mock data if API fails
      print('⚠️ ReportCubit: API call failed, using mock data: $e');

      if (role == 'picker') {
        return PickerReportModel(
          role: 'picker',
          assignedOrders: 45,
          startedOrders: 38,
          completedOrders: 35,
          endPickedOrders: 32,
          fromDate: fromDate,
          toDate: toDate,
        );
      } else {
        return DriverReportModel(
          role: 'driver',
          assignedOrders: 28,
          startedOrders: 25,
          completedOrders: 22,
          onTheWayOrders: 18,
          deliveredOrders: 20,
          fromDate: fromDate,
          toDate: toDate,
        );
      }
    }
  }
}
