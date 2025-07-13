import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/register_request_model.dart';
import '../../domain/usecases/register_cases.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final RegisterCases registerCases;

  RegisterCubit({required this.registerCases}) : super(RegisterInitial());

  Future<void> register(RegisterRequestModel registerRequestModel) async {
    emit(RegisterLoading());
    try {
      final registerResponseModel = await registerCases.register(
        registerRequestModel,
      );

      if (registerResponseModel.success) {
        emit(RegisterSuccess());
      } else {
        emit(
          RegisterFailure(
            message: registerResponseModel.message ?? 'Registration failed',
          ),
        );
      }
    } catch (e) {
      emit(RegisterFailure(message: e.toString()));
    }
  }
}
