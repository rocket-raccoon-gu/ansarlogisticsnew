part of 'bill_upload_cubit.dart';

abstract class BillUploadState extends Equatable {
  const BillUploadState();
  @override
  List<Object?> get props => [];
}

class BillUploadInitial extends BillUploadState {}

class BillUploadLoading extends BillUploadState {}

class BillUploadImageSelected extends BillUploadState {
  final File imageFile;
  const BillUploadImageSelected(this.imageFile);
  @override
  List<Object?> get props => [imageFile];
}

class BillUploadUploading extends BillUploadState {}

class BillUploadSuccess extends BillUploadState {}

class BillUploadDelivered extends BillUploadState {}

class BillUploadError extends BillUploadState {
  final String message;
  const BillUploadError(this.message);
  @override
  List<Object?> get props => [message];
}
