import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:geolocator/geolocator.dart';

part 'bill_upload_state.dart';

class BillUploadCubit extends Cubit<BillUploadState> {
  final ApiService _apiService;
  final ImagePicker _imagePicker;

  BillUploadCubit({ApiService? apiService})
    : _apiService = apiService ?? ApiService(HttpClient(), WebSocketClient()),
      _imagePicker = ImagePicker(),
      super(BillUploadInitial());

  Future<File?> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(
      dir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60, // Lower quality for smaller size
      minWidth: 800,
      minHeight: 800,
      format: CompressFormat.jpeg,
    );
    return result == null ? null : File(result.path);
  }

  Future<void> pickImageFromCamera() async {
    emit(BillUploadLoading());
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        final compressed = await _compressImage(File(image.path));
        if (compressed != null) {
          emit(BillUploadImageSelected(compressed));
        } else {
          emit(BillUploadError('Failed to compress image.'));
        }
      } else {
        emit(BillUploadInitial());
      }
    } catch (e) {
      emit(BillUploadError('Failed to capture image: ${e.toString()}'));
    }
  }

  Future<void> pickImageFromGallery() async {
    emit(BillUploadLoading());
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        final compressed = await _compressImage(File(image.path));
        if (compressed != null) {
          emit(BillUploadImageSelected(compressed));
        } else {
          emit(BillUploadError('Failed to compress image.'));
        }
      } else {
        emit(BillUploadInitial());
      }
    } catch (e) {
      emit(BillUploadError('Failed to pick image: ${e.toString()}'));
    }
  }

  Future<void> uploadBill(String orderId, String token) async {
    final currentState = state;
    if (currentState is! BillUploadImageSelected) {
      emit(BillUploadError('No image selected'));
      return;
    }

    emit(BillUploadUploading());
    try {
      final location = await Geolocator.getCurrentPosition();
      final latitude = location.latitude;
      final longitude = location.longitude;
      await _apiService.uploadBill(
        orderId,
        currentState.imageFile,
        token,
        latitude,
        longitude,
      );
      emit(BillUploadSuccess());
    } catch (e) {
      emit(BillUploadError('Failed to upload bill: ${e.toString()}'));
    }
  }

  Future<void> markAsDelivered(String orderId, String token) async {
    emit(BillUploadLoading());
    try {
      await _apiService.updateOrderStatusDriver(token, orderId, 'delivered');
      emit(BillUploadDelivered());
    } catch (e) {
      emit(BillUploadError('Failed to mark as delivered: ${e.toString()}'));
    }
  }

  void reset() {
    emit(BillUploadInitial());
  }
}
