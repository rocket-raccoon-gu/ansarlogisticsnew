import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/widgets/safe_app_bar.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;
  final VoidCallback? onResetScanner;
  final String? title;
  final String? subtitle;

  const BarcodeScannerWidget({
    super.key,
    required this.onBarcodeScanned,
    this.onResetScanner,
    this.title,
    this.subtitle,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget>
    with WidgetsBindingObserver {
  MobileScannerController? controller;
  bool _isScanning = true;
  bool _hasPermission = false;
  String? _lastScannedBarcode;
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _isStarting = false; // Track if controller is starting

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      setState(() {
        _isInitialized = false;
        _isStarting = false;
        _isScanning = false;
      });

      // Force cleanup of any existing camera resources
      await _forceCleanupCameraResources();

      // Check if camera is available before creating controller
      await _checkCameraAvailability();

      // Create new controller with error handling
      controller = MobileScannerController(
        autoStart: false, // Disable auto start to prevent conflicts
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: [BarcodeFormat.all],
        torchEnabled: false,
      );

      await _checkPermission();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Start the scanner after initialization with longer delay
        if (_hasPermission && !_isStarting) {
          await Future.delayed(
            const Duration(seconds: 2),
          ); // Increased delay to ensure camera is ready
          if (mounted && controller != null) {
            if (mounted) {
              setState(() {
                _isStarting = true;
              });
            }
            try {
              await controller!.start();
              if (mounted) {
                setState(() {
                  _isStarting = false;
                  _isScanning = true;
                });
              }
            } catch (e) {
              print('Error starting scanner: $e');
              if (mounted) {
                setState(() {
                  _isStarting = false;
                  _isScanning = false;
                });
              }
              // If initialization fails, try to recover
              await _recoverFromCameraError();
            }
          }
        }
      }
    } catch (e) {
      print('Scanner initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _isScanning = false;
        });
      }
      // Try to recover from initialization error
      await _recoverFromCameraError();
    }
  }

  // Check if camera is available before initializing
  Future<void> _checkCameraAvailability() async {
    try {
      // Wait a bit to ensure camera resources are freed
      await Future.delayed(const Duration(seconds: 1));

      // Try to create a temporary controller to test camera availability
      final tempController = MobileScannerController(
        autoStart: false,
        facing: CameraFacing.back,
      );

      // If we can create the controller, camera is available
      await tempController.dispose();

      print('Camera availability check passed');
    } catch (e) {
      print('Camera availability check failed: $e');
      // Wait longer before retrying
      await Future.delayed(const Duration(seconds: 3));
      throw Exception('Camera not available: $e');
    }
  }

  // Show troubleshooting dialog
  void _showTroubleshootingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Troubleshooting Tips'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'If camera is not working, try these steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. Close other apps that might be using the camera'),
              Text('2. Restart your device'),
              Text('3. Check camera permissions in device settings'),
              Text('4. Try using manual barcode entry instead'),
              SizedBox(height: 12),
              Text(
                'You can always use manual entry by typing the barcode number.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Force cleanup of camera resources
  Future<void> _forceCleanupCameraResources() async {
    try {
      print('Starting camera resource cleanup...');

      // Dispose existing controller if any
      if (controller != null) {
        try {
          print('Stopping existing controller...');
          await controller!.stop();
        } catch (e) {
          print('Error stopping controller during cleanup: $e');
        }
        try {
          print('Disposing existing controller...');
          controller!.dispose();
        } catch (e) {
          print('Error disposing controller during cleanup: $e');
        }
        controller = null;
      }

      // Force garbage collection to free camera resources
      await Future.delayed(const Duration(milliseconds: 1000));

      // Additional delay to ensure camera resources are freed
      await Future.delayed(const Duration(milliseconds: 2000));

      print('Camera resource cleanup completed');
    } catch (e) {
      print('Error during camera resource cleanup: $e');
    }
  }

  // Method to recover from camera errors
  Future<void> _recoverFromCameraError() async {
    if (!mounted) return;

    print('Attempting to recover from camera error...');

    // Force cleanup of camera resources
    await _forceCleanupCameraResources();

    // Wait longer before reinitializing to ensure camera is fully released
    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      // Try to reinitialize with a fresh start
      await _initializeScanner();
    }
  }

  Future<void> _checkPermission() async {
    try {
      final status = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _hasPermission = status.isGranted;
        });
      }
    } catch (e) {
      print('Permission check error: $e');
      if (mounted) {
        setState(() {
          _hasPermission = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (controller != null && _isInitialized && !_isStarting) {
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
          try {
            // Stop scanning immediately
            controller!.stop();
            if (mounted) {
              setState(() {
                _isScanning = false;
              });
            }
          } catch (e) {
            print('Error stopping scanner: $e');
          }
          break;
        case AppLifecycleState.resumed:
          if (_hasPermission && !_isProcessing) {
            // Add a longer delay to ensure camera is fully ready
            Future.delayed(const Duration(seconds: 3), () async {
              if (mounted && controller != null && !_isStarting) {
                if (mounted) {
                  setState(() {
                    _isStarting = true;
                  });
                }
                try {
                  await controller!.start();
                  if (mounted) {
                    setState(() {
                      _isStarting = false;
                      _isScanning = true;
                    });
                  }
                } catch (e) {
                  print('Error resuming scanner: $e');
                  if (mounted) {
                    setState(() {
                      _isStarting = false;
                      _isScanning = false;
                    });
                  }
                  // If start fails, try to recover with full cleanup
                  Future.delayed(const Duration(seconds: 2), () async {
                    if (mounted) {
                      await _handleBrokenPipeError();
                    }
                  });
                }
              }
            });
          }
          break;
        default:
          break;
      }
    }
  }

  // Handle broken pipe errors specifically
  Future<void> _handleBrokenPipeError() async {
    if (!mounted) return;

    print('Handling broken pipe error...');

    // Force complete cleanup
    await _forceCleanupCameraResources();

    // Wait for camera to be fully released
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      // Reinitialize with fresh resources
      await _initializeScanner();
    }
  }

  // Handle device connection lost error
  Future<void> _handleDeviceConnectionLost() async {
    if (!mounted) return;

    print('Handling device connection lost error...');

    // Force complete cleanup with longer delays
    await _forceCleanupCameraResources();

    // Wait longer for device to stabilize
    await Future.delayed(const Duration(seconds: 6));

    if (mounted) {
      // Try to reinitialize with fresh resources
      await _initializeScanner();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _forceDisposeCamera();
    super.dispose();
  }

  // Force dispose camera with proper cleanup
  Future<void> _forceDisposeCamera() async {
    try {
      // Stop the scanner before disposing
      if (controller != null && _isScanning) {
        try {
          await controller!.stop();
        } catch (e) {
          print('Error stopping scanner before dispose: $e');
        }
      }

      // Add a longer delay before disposing to ensure proper cleanup
      await Future.delayed(const Duration(milliseconds: 500));

      if (controller != null) {
        try {
          controller!.dispose();
        } catch (e) {
          print('Error disposing scanner: $e');
        }
        controller = null;
      }

      // Additional cleanup delay
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('Error during camera disposal: $e');
    }
  }

  void _handleBarcodeDetected(String barcode) {
    // Prevent multiple rapid scans of the same barcode
    if (_isProcessing || _lastScannedBarcode == barcode) {
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = true;
        _lastScannedBarcode = barcode;
      });
    }

    // Stop scanning temporarily
    try {
      controller?.stop();
    } catch (e) {
      print('Error stopping scanner: $e');
    }

    // Call the callback
    widget.onBarcodeScanned(barcode);

    // Reset after a delay to allow for processing
    Future.delayed(const Duration(seconds: 1), () async {
      // Double check if still mounted before any setState calls
      if (!mounted) return;

      if (!_isStarting) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isStarting = true;
          });
        }
        // Resume scanning with retry mechanism
        await _resumeScanningWithRetry();
      }
    });

    // Reset the last scanned barcode after a longer delay to allow retry
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _lastScannedBarcode = null; // Allow retry of the same barcode
        });
      }
    });
  }

  // Enhanced method to resume scanning with retry mechanism
  Future<void> _resumeScanningWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries && mounted) {
      try {
        if (controller != null) {
          await controller!.start();
          if (mounted) {
            setState(() {
              _isStarting = false;
            });
          }
          return; // Success, exit retry loop
        }
      } catch (e) {
        print('Error resuming scanner (attempt ${retryCount + 1}): $e');
        retryCount++;

        if (retryCount < maxRetries) {
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(milliseconds: 1000 * retryCount));

          // Try to reinitialize controller if needed
          if (mounted && controller == null) {
            await _forceCleanupCameraResources();
            await Future.delayed(const Duration(seconds: 2));
            await _initializeScanner();
          }
        } else {
          // Max retries reached, set error state
          if (mounted) {
            setState(() {
              _isStarting = false;
              _isScanning = false;
            });
          }
          print('Failed to resume scanner after $maxRetries attempts');

          // Try one final recovery attempt
          if (mounted) {
            await _recoverFromCameraError();
          }
        }
      }
    }
  }

  // Method to reset scanner state when API call fails
  void resetScannerState() {
    if (mounted && !_isStarting) {
      setState(() {
        _isProcessing = false;
        _lastScannedBarcode = null; // Reset to allow retry of same barcode
        _isStarting = true;
      });
      // Resume scanning immediately with retry mechanism
      Future.delayed(const Duration(milliseconds: 500), () async {
        // Double check if still mounted before any setState calls
        if (!mounted) return;

        if (controller != null) {
          await _resumeScanningWithRetry();
        } else {
          // If controller is null, try to reinitialize
          if (mounted) {
            await _initializeScanner();
          }
        }
      });
    }
    // Call the reset callback if provided
    widget.onResetScanner?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: SafeAppBar(
          title: 'Initializing Scanner',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        appBar: SafeAppBar(
          title: 'Camera Permission',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Camera Permission Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app needs camera access to scan barcodes',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkPermission,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    if (controller == null) {
      return Scaffold(
        appBar: SafeAppBar(
          title: 'Scanner Error',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Camera Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to initialize camera. This might be due to:\n• Camera being used by another app\n• Device restart required\n• Permission issues',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _initializeScanner,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate back to allow manual entry
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Manual Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Show troubleshooting tips
                  _showTroubleshootingDialog(context);
                },
                child: const Text('Troubleshooting Tips'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: SafeAppBar(
        title: widget.title ?? 'Scan Barcode',
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isScanning = !_isScanning;
                if (_isScanning) {
                  try {
                    controller!.start();
                  } catch (e) {
                    print('Error starting scanner: $e');
                  }
                } else {
                  try {
                    controller!.stop();
                  } catch (e) {
                    print('Error stopping scanner: $e');
                  }
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () {
              try {
                controller!.switchCamera();
              } catch (e) {
                print('Error switching camera: $e');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.subtitle != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Text(
                widget.subtitle!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (_isProcessing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(width: 16),
                  Text(
                    'Processing barcode: $_lastScannedBarcode',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller!,
                  onDetect: (capture) {
                    try {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          _handleBarcodeDetected(barcode.rawValue!);
                          break; // Only process the first barcode
                        }
                      }
                    } catch (e) {
                      print('Error processing barcode: $e');
                    }
                  },
                  errorBuilder: (context, error) {
                    // Handle specific camera errors
                    if (error.errorDetails?.message?.contains(
                              'STATUS_NOT_AVAILABLE',
                            ) ==
                            true ||
                        error.errorDetails?.message?.contains(
                              'Lost connection',
                            ) ==
                            true) {
                      // Handle camera not available or connection lost
                      Future.delayed(Duration(milliseconds: 100), () {
                        _handleDeviceConnectionLost();
                      });
                    }

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 80, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Camera Error: ${error.errorCode}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.errorDetails?.message ??
                                'Unknown error occurred',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Attempting to recover automatically...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  try {
                                    controller?.start();
                                  } catch (e) {
                                    print('Error restarting scanner: $e');
                                  }
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate back to allow manual entry
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.keyboard),
                                label: const Text('Manual Entry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Center scan area indicator
                Center(
                  child: Container(
                    width: 250,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill;

    // Draw semi-transparent overlay
    canvas.drawRect(Offset.zero & size, paint);

    // Clear the scan area
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 250,
      height: 150,
    );

    final clearPaint =
        Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.clear;

    canvas.drawRect(scanArea, clearPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
