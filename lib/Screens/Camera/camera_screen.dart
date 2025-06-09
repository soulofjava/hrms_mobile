// ignore_for_file: library_private_types_in_public_api, use_super_parameters, curly_braces_in_flow_control_structures

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hrms/Screens/Home/home_screen.dart';
import 'package:hrms/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String status;
  const CameraScreen({Key? key, required this.cameras, this.status = 'present'})
    : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraReady = false;
  bool _isUploading = false;
  bool _isDisposed = false;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize the front camera
    _initializeCamera(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    // App state changed before we got the chance to initialize
    if (_controller == null || !_isCameraInitialized) return;

    if (state == AppLifecycleState.inactive) {
      // App is in background or inactive, dispose camera to prevent issues
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      // App is resumed, reinitialize camera if needed
      if (!_isCameraReady) {
        _initializeCamera(true);
      }
    }
  }

  Future<void> _initializeCamera(bool frontCamera) async {
    if (_isDisposed) return;

    // First dispose any existing camera
    await _disposeCamera();

    try {
      // Find the front camera
      CameraDescription camera = widget.cameras.firstWhere(
        (camera) =>
            camera.lensDirection ==
            (frontCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back),
        orElse: () => widget.cameras.first,
      );

      // Create a new controller
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Create a future for the initialization
      _initializeControllerFuture = _controller?.initialize();

      // Wait for the controller to initialize
      if (!_isDisposed && _initializeControllerFuture != null) {
        await _initializeControllerFuture;

        if (!_isDisposed && mounted && _controller != null) {
          setState(() {
            _isCameraReady = true;
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      if (_isDisposed) return;
      
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            toast(
              'Akses kamera ditolak. Mohon berikan izin kamera di pengaturan.',
            );
            break;
          default:
            toast('Error: ${e.code}\n${e.description}');
            break;
        }
      } else {
        toast('Error initializing camera: $e');
      }
      print('CameraScreen Error initializing camera: $e');
    }
  }

  Future<void> _disposeCamera() async {
    if (_controller != null && _isCameraInitialized) {
      try {
        final CameraController controller = _controller!;
        _controller = null;
        _isCameraInitialized = false;
        _isCameraReady = false;
        
        await controller.dispose();
        
        if (mounted && !_isDisposed) {
          setState(() {});
        }
      } catch (e) {
        print("Error disposing camera: $e");
      }
    }
  }

  @override
  void dispose() {
    print("CameraScreen dispose called");
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);

    // Dispose camera resources
    _disposeCamera();
    super.dispose();
  }

  Future<String> _takePicture() async {
    if (_isDisposed || !mounted || _controller == null || !_isCameraInitialized || !_isCameraReady) {
      throw Exception('Camera not available');
    }

    try {
      // Ensure the camera is initialized
      if (_initializeControllerFuture != null) {
        await _initializeControllerFuture;
      }

      // Check if controller is still initialized
      if (_controller == null || !_controller!.value.isInitialized) {
        throw Exception('Camera is not initialized');
      }

      // Get the directory for storing images
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/Pictures/flutter_camera';
      await Directory(dirPath).create(recursive: true);

      // Generate a unique file name
      final String filePath =
          '$dirPath/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Take the picture
      final XFile image = await _controller!.takePicture();

      // Copy the image to our custom location
      await File(image.path).copy(filePath);

      // Try to delete the original file
      try {
        await File(image.path).delete();
      } catch (e) {
        print('Error deleting temporary file: $e');
      }

      return filePath;
    } catch (e) {
      print('CameraScreen Error taking picture: $e');
      rethrow;
    }
  }

  // Add this method to properly close the camera
  Future<void> _stopCameraAndCleanup() async {
    try {
      await _disposeCamera();
      print("CameraScreen Camera resources closed successfully");
    } catch (e) {
      print("CameraScreen Error closing camera resources: $e");
    }
  }

  Future<void> _uploadAttendance(String imagePath) async {
    if (!mounted || _isDisposed) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      // Get token from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      print("CameraScreen tokenku: $token");

      if (token == null || token.isEmpty) {
        if (!mounted || _isDisposed) return;
        toast(
          'Sesi login telah berakhir. Silakan login kembali.',
          bgColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Determine endpoint based on status
      final String endpoint = widget.status.isEmpty
          ? '/attendance/clock-out' // Empty status means clock-out
          : '/attendance/clock-in'; // Non-empty status means clock-in

      print("CameraScreen API URL: $apiBaseUrl$endpoint");
      print("CameraScreen Status: '${widget.status}'");

      // Check if file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        if (!mounted || _isDisposed) return;
        toast(
          'File gambar tidak ditemukan',
          bgColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Print file info for debugging
      print("CameraScreen File size: ${await file.length()} bytes");
      print("CameraScreen File path: $imagePath");

      // Create multipart request with the appropriate endpoint
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl$endpoint'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      print("CameraScreen Headers: ${request.headers}");

      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      final multipartFile = http.MultipartFile(
        'image', // Make sure this field name matches what your API expects
        fileStream,
        fileLength,
        filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      // Add status field only if it's not empty (clock-in)
      if (widget.status.isNotEmpty) {
        request.fields['status'] = widget.status;
      }

      print("CameraScreen Request fields: ${request.fields}");
      print("CameraScreen Files to upload: ${request.files.length}");

      // Send the request with timeout
      if (!mounted || _isDisposed) return;
      toast('Mengirim data presensi...');

      try {
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timeout');
          },
        );

        print("CameraScreen Response status: ${streamedResponse.statusCode}");

        final response = await http.Response.fromStream(streamedResponse);
        print("CameraScreen Response body: ${response.body}");

        // Check the response
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = json.decode(response.body);
          print("CameraScreen Response data: $responseData");

          // Access the message from the nested 'meta' object
          final message =
              responseData['meta']?['message'] ?? 'Presensi berhasil';
          final data = responseData['data'] ?? '';

          if (!mounted || _isDisposed) return;
          toast(
            '$message: $data',
            bgColor: Colors.green,
            textColor: Colors.white,
          );

          // Properly close camera resources before navigating
          await _stopCameraAndCleanup();

          if (context.mounted && !_isDisposed) {
            Future.delayed(Duration.zero, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            });
          }
        } else {
          // Handle error
          Map<String, dynamic> errorData = {};
          try {
            errorData = json.decode(response.body);
            print("CameraScreen Error data: $errorData");

            // Special handling for already clocked in/out error (code 422)
            if (errorData['meta']?['code'] == 422) {
              final errorMessage = errorData['data']?['message'] ?? '';

              if (errorMessage.contains("already clocked in") ||
                  errorMessage.contains("already clocked out")) {
                if (!mounted || _isDisposed) return;
                toast(
                  widget.status.isEmpty
                      ? 'Anda sudah melakukan presensi pulang hari ini.'
                      : 'Anda sudah melakukan presensi masuk hari ini.',
                  bgColor: Colors.orange,
                  textColor: Colors.white,
                );

                // Close the camera and return to previous screen
                await _stopCameraAndCleanup();

                if (context.mounted && !_isDisposed) {
                  const HomeScreen().launch(context);
                }
                return;
              }
            }

            // Handle other errors
            final metaMessage = errorData['meta']?['message'];
            final dataMessage = errorData['data']?['message'];
            final fallbackMessage =
                'Gagal mengirim presensi. Silakan coba lagi.';

            // Use the most specific error message available
            final errorMessage = dataMessage ?? metaMessage ?? fallbackMessage;

            if (!mounted || _isDisposed) return;
            toast(errorMessage, bgColor: Colors.red, textColor: Colors.white);
          } catch (e) {
            print('CameraScreen Error parsing response: $e');
            if (!mounted || _isDisposed) return;
            toast(
              'Gagal mengirim presensi. Format respons tidak valid.',
              bgColor: Colors.red,
              textColor: Colors.white,
            );
          }
          print('CameraScreen API Error: ${response.body}');
        }
      } catch (e) {
        if (!mounted || _isDisposed) return;
        if (e is TimeoutException) {
          toast(
            'Waktu permintaan habis. Periksa koneksi Anda.',
            bgColor: Colors.red,
            textColor: Colors.white,
          );
        } else {
          toast(
            'Terjadi kesalahan koneksi: ${e.toString()}',
            bgColor: Colors.red,
            textColor: Colors.white,
          );
        }
        print('CameraScreen Request error: $e');
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      toast(
        'Terjadi kesalahan: ${e.toString()}',
        bgColor: Colors.red,
        textColor: Colors.white,
      );
      print('CameraScreen Exception during upload: $e');
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return Container(); // Return empty container if disposed
    }
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Clean up camera resources before popping
        await _stopCameraAndCleanup();
        if (context.mounted && !_isDisposed) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: kMainColor,
        appBar: AppBar(
          title: Text(
            widget.status.isEmpty
                ? 'Ambil Selfie untuk Pulang'
                : 'Ambil Selfie untuk Masuk',
            style: kTextStyle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: kMainColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20.0),
            Expanded(
              child: Container(
                width: context.width(),
                padding: const EdgeInsets.only(top: 20.0),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                  color: Colors.white,
                ),
                child: _buildCameraContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Separate the camera content building logic
  Widget _buildCameraContent() {
    if (_isDisposed) {
      return const Center(child: Text('Camera disposed'));
    }

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            _isCameraReady &&
            mounted &&
            !_isDisposed &&
            _isCameraInitialized &&
            _controller != null &&
            _controller!.value.isInitialized) {
          // If the Future is complete, display the preview
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Posisikan wajah Anda di dalam frame kamera',
                  style: kTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Using Expanded to fill available space
              Expanded(child: _buildCameraPreview()),
              Container(
                height: 100,
                color: Colors.transparent,
                child: Center(
                  child: _isUploading
                      ? const CircularProgressIndicator(color: kMainColor)
                      : FloatingActionButton.large(
                          backgroundColor: kMainColor,
                          child: const Icon(Icons.camera_alt, size: 32),
                          onPressed: _onCaptureButtonPressed,
                        ),
                ),
              ),
            ],
          );
        } else {
          // Otherwise, display a loading indicator
          return const Center(
            child: CircularProgressIndicator(color: kMainColor),
          );
        }
      },
    );
  }

  Widget _buildCameraPreview() {
    try {
      if (_controller == null || 
          !_isCameraInitialized ||
          !_controller!.value.isInitialized ||
          _isDisposed) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Text(
              'Camera initializing...',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: CameraPreview(_controller!),
        ),
      );
    } catch (e) {
      print('Error building camera preview: $e');
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'Camera error: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _onCaptureButtonPressed() async {
    if (_isUploading || !mounted || _isDisposed || !_isCameraInitialized || _controller == null)
      return;

    try {
      setState(() {
        _isUploading = true;
      });

      // Display a loading indicator while we take the picture
      toast('Mengambil foto...');

      // Take the picture
      final String imagePath = await _takePicture();

      // Upload attendance with image
      await _uploadAttendance(imagePath);
    } catch (e) {
      // If an error occurs, log the error to the console.
      print('Error: $e');
      if (mounted && !_isDisposed) {
        toast('Error: $e');
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}
