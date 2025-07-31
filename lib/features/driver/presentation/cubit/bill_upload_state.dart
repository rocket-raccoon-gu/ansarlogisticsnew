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

class BillUploadUploading extends BillUploadState {
  final String message;
  final double progress;
  const BillUploadUploading({
    this.message = 'Uploading bill image...',
    this.progress = 0.0,
  });
  @override
  List<Object?> get props => [message, progress];
}

class BillUploadSuccess extends BillUploadState {}

class BillUploadDelivering extends BillUploadState {
  final String message;
  const BillUploadDelivering({this.message = 'Marking order as delivered...'});
  @override
  List<Object?> get props => [message];
}

class BillUploadDelivered extends BillUploadState {}

class BillUploadError extends BillUploadState {
  final String message;
  const BillUploadError(this.message);
  @override
  List<Object?> get props => [message];
}
