import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer';

class DebugScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  const DebugScannerWidget({super.key, required this.onBarcodeScanned});

  @override
  State<DebugScannerWidget> createState() => _DebugScannerWidgetState();
}

class _DebugScannerWidgetState extends State<DebugScannerWidget> {
  MobileScannerController? controller;
  bool _hasPermission = false;
  bool _isInitializing = true;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    setState(() {
      _status = 'Checking camera permission...';
    });

    try {
      // Check if permission is already granted (should be granted during initial permission dialog)
      final status = await Permission.camera.status;
      setState(() {
        _hasPermission = status.isGranted;
        _status =
            status.isGranted
                ? 'Permission granted'
                : 'Permission not granted - check settings';
      });

      if (_hasPermission) {
        _createController();
      } else {
        log(
          "❌ Camera permission not granted - should be granted during initial permission dialog",
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Permission error: $e';
      });
    }
  }

  void _createController() {
    setState(() {
      _status = 'Creating scanner controller...';
    });

    try {
      controller = MobileScannerController(
        autoStart: true,
        facing: CameraFacing.back,
        formats: [BarcodeFormat.all],
      );

      setState(() {
        _isInitializing = false;
        _status = 'Scanner ready';
      });

      log("📱 Debug scanner: Controller created successfully");
    } catch (e) {
      setState(() {
        _status = 'Controller error: $e';
      });
      log("❌ Debug scanner: Controller creation failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Scanner'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isInitializing = true;
                _status = 'Restarting...';
              });
              _checkPermission();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug info
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug Info:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Permission: ${_hasPermission ? "Granted" : "Denied"}'),
                Text('Controller: ${controller != null ? "Created" : "Null"}'),
                Text('Initializing: $_isInitializing'),
                Text('Status: $_status'),
              ],
            ),
          ),

          // Scanner or fallback
          Expanded(
            child:
                _hasPermission && controller != null && !_isInitializing
                    ? MobileScanner(
                      controller: controller!,
                      onDetect: (capture) {
                        final barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            log(
                              "📱 Debug scanner detected: ${barcode.rawValue}",
                            );
                            widget.onBarcodeScanned(barcode.rawValue!);
                            break;
                          }
                        }
                      },
                      errorBuilder: (context, error) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                'Camera Error: ${error.errorCode}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                error.errorDetails?.message ?? 'Unknown error',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isInitializing = true;
                                    _status = 'Retrying...';
                                  });
                                  _checkPermission();
                                },
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                    : Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _status,
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            if (!_hasPermission)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: ElevatedButton(
                                  onPressed: _checkPermission,
                                  child: Text('Grant Permission'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
