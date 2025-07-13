import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/info_data_response_model.dart';
import '../../domain/repositories/auth_repository.dart';

part 'info_data_state.dart';

class InfoDataCubit extends Cubit<InfoDataState> {
  final AuthRepository authRepository;

  InfoDataCubit({required this.authRepository}) : super(InfoDataInitial());

  Future<void> getInfoData() async {
    emit(InfoDataLoading());
    try {
      final infoDataResponseModel = await authRepository.getInfoData();

      if (infoDataResponseModel.success) {
        emit(InfoDataSuccess(infoDataResponseModel: infoDataResponseModel));
      } else {
        emit(InfoDataFailure(message: 'Failed to load info data'));
      }
    } catch (e) {
      emit(InfoDataFailure(message: e.toString()));
    }
  }
}
