part of 'info_data_cubit.dart';

abstract class InfoDataState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InfoDataInitial extends InfoDataState {}

class InfoDataLoading extends InfoDataState {}

class InfoDataSuccess extends InfoDataState {
  final InfoDataResponseModel infoDataResponseModel;

  InfoDataSuccess({required this.infoDataResponseModel});

  @override
  List<Object?> get props => [infoDataResponseModel];
}

class InfoDataFailure extends InfoDataState {
  final String message;

  InfoDataFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
