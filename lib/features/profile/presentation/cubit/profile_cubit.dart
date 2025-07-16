import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/user_storage_service.dart';
import 'package:api_gateway/api_gateway.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileLoading());

  Future<void> fetchUserData() async {
    emit(ProfileLoading());
    try {
      final userData = await UserStorageService.getUserData();
      if (userData != null && userData.user != null) {
        emit(ProfileLoaded(user: userData.user!));
      } else {
        emit(ProfileError('No user data found.'));
      }
    } catch (e) {
      emit(ProfileError('Failed to load user data.'));
    }
  }

  Future<void> updateAvailabilityStatus(bool isOnDuty) async {
    final userData = await UserStorageService.getUserData();
    if (userData != null && userData.user != null) {
      await ApiGateway(apiService: ApiService(HttpClient(), WebSocketClient()))
          .updateAvailabilityStatus(isOnDuty ? 1 : 0, userData.user!.id)
          .then((value) {
            if (value.statusCode == 200) {
              emit(ProfileLoaded(user: userData.user!));
            } else {
              emit(ProfileError('Failed to update availability status.'));
            }
          })
          .catchError((error) {
            emit(ProfileError('Failed to update availability status.'));
          });
    }
    await fetchUserData();
  }
}
