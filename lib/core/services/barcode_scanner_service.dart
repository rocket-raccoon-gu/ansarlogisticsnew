import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer';
import 'dart:async';

class BarcodeScannerService {
  static final BarcodeScannerService _instance =
      BarcodeScannerService._internal();
  factory BarcodeScannerService() => _instance;
  BarcodeScannerService._internal();

  MobileScannerController? _controller;
  bool _isInitialized = false;
  bool _isStarting = false;
  bool _hasPermission = false;
  bool _isScanning = false;
  String? _lastScannedBarcode;
  bool _isProcessing = false;
  bool _isAttached = false; // Track if controller is attached to widget

  // Stream controller for barcode results
  final _barcodeController = StreamController<String>.broadcast();
  Stream<String> get barcodeStream => _barcodeController.stream;

  // Getters for state
  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  bool get hasPermission => _hasPermission;
  bool get isProcessing => _isProcessing;
  bool get isAttached => _isAttached;

  // Initialize the scanner service (call this once at app startup)
  Future<void> initialize() async {
    if (_isInitialized) {
      log("📱 Scanner service already initialized");
      return;
    }

    try {
      log("🚀 Initializing barcode scanner service...");

      // Check camera permission
      await _checkPermission();

      if (!_hasPermission) {
        log("❌ Camera permission not granted");
        return;
      }

      // Create controller
      _controller = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: [BarcodeFormat.all],
        torchEnabled: false,
      );

      // Set up barcode listener
      _controller!.barcodes.listen((capture) {
        if (!_isProcessing) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              final scannedBarcode = barcode.rawValue!;

              // Prevent duplicate scans
              if (scannedBarcode != _lastScannedBarcode) {
                _lastScannedBarcode = scannedBarcode;
                log("📱 Barcode scanned: $scannedBarcode");
                _barcodeController.add(scannedBarcode);
              }
              break; // Only process the first barcode
            }
          }
        }
      });

      _isInitialized = true;
      log("✅ Barcode scanner service initialized successfully");
    } catch (e) {
      log("❌ Error initializing scanner service: $e");
      _isInitialized = false;
    }
  }

  // Mark controller as attached (called when MobileScanner widget is built)
  void markAsAttached() {
    log("📱 markAsAttached called - was attached: $_isAttached");
    _isAttached = true;
    log("📱 Scanner controller attached to widget");
  }

  // Mark controller as detached (called when MobileScanner widget is disposed)
  void markAsDetached() {
    log("📱 markAsDetached called - was attached: $_isAttached");
    _isAttached = false;
    _isScanning = false;
    log("📱 Scanner controller detached from widget");
  }

  // Start scanning (only after widget is attached)
  Future<bool> startScanning() async {
    log(
      "📱 startScanning called - initialized: $_isInitialized, starting: $_isStarting, scanning: $_isScanning, attached: $_isAttached",
    );

    if (!_isInitialized || _isStarting || _isScanning) {
      log("📱 Scanner not ready or already scanning");
      return false;
    }

    if (!_isAttached) {
      log("📱 Scanner controller not attached to widget yet");
      return false;
    }

    try {
      log("📱 Starting barcode scanner...");
      _isStarting = true;
      _isProcessing = false;
      _lastScannedBarcode = null;

      await _controller!.start();

      _isStarting = false;
      _isScanning = true;
      log("✅ Barcode scanner started successfully");
      return true;
    } catch (e) {
      log("❌ Error starting scanner: $e");
      _isStarting = false;
      _isScanning = false;
      return false;
    }
  }

  // Stop scanning
  Future<void> stopScanning() async {
    if (!_isScanning) {
      return;
    }

    try {
      log("📱 Stopping barcode scanner...");
      await _controller!.stop();
      _isScanning = false;
      _isProcessing = false;
      log("✅ Barcode scanner stopped");
    } catch (e) {
      log("❌ Error stopping scanner: $e");
    }
  }

  // Pause scanning (for processing)
  void pauseForProcessing() {
    _isProcessing = true;
    log("📱 Scanner paused for processing");
  }

  // Resume scanning (after processing)
  void resumeFromProcessing() {
    _isProcessing = false;
    log("📱 Scanner resumed from processing");
  }

  // Check camera permission
  Future<bool> _checkPermission() async {
    try {
      // Check if permission is already granted (should be granted during initial permission dialog)
      final status = await Permission.camera.status;
      _hasPermission = status.isGranted;

      if (!_hasPermission) {
        log(
          "❌ Camera permission not granted - should be granted during initial permission dialog",
        );
      }

      return _hasPermission;
    } catch (e) {
      log("❌ Error checking camera permission: $e");
      _hasPermission = false;
      return false;
    }
  }

  // Get the controller for UI
  MobileScannerController? get controller => _controller;

  // Dispose the service (call this when app is closing)
  Future<void> dispose() async {
    try {
      log("📱 Disposing barcode scanner service...");

      if (_controller != null) {
        await _controller!.stop();
        await _controller!.dispose();
        _controller = null;
      }

      await _barcodeController.close();

      _isInitialized = false;
      _isScanning = false;
      _isStarting = false;
      _hasPermission = false;
      _isProcessing = false;
      _isAttached = false;

      log("✅ Barcode scanner service disposed");
    } catch (e) {
      log("❌ Error disposing scanner service: $e");
    }
  }

  // Reset for new scan session
  void resetForNewSession() {
    _lastScannedBarcode = null;
    _isProcessing = false;
    log("📱 Scanner reset for new session");
  }
}
