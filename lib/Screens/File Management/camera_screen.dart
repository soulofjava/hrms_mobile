// ignore_for_file: library_private_types_in_public_api, use_super_parameters

import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hrms/Screens/File%20Management/empty_file_management.dart';
import 'package:hrms/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCameraReady = false;
  bool _isProcessingFrame = false;
  bool _isFaceDetected = false;

  // Face detector
  late FaceDetector _faceDetector;

  // Timer for periodic face detection
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initialize the face detector with options
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);

    // Initialize the front camera
    _initializeCamera(true);
  }

  Future<void> _initializeCamera(bool frontCamera) async {
    // Find the front camera
    CameraDescription camera = widget.cameras.firstWhere(
      (camera) =>
          camera.lensDirection ==
          (frontCamera ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => widget.cameras.first,
    );

    // Initialize the controller
    _controller = CameraController(camera, ResolutionPreset.medium);

    // Initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();

    // Only update the state if the widget is still mounted
    if (mounted) {
      _initializeControllerFuture
          .then((_) {
            setState(() {
              _isCameraReady = true;
            });

            // Start face detection timer
            _startFaceDetection();
          })
          .catchError((Object e) {
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
            }
          });
    }
  }

  // Start periodic face detection
  void _startFaceDetection() {
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (_isCameraReady && !_isProcessingFrame && mounted) {
        await _processCameraImage();
      }
    });
  }

  Future<void> _processCameraImage() async {
    if (_isProcessingFrame) return;

    _isProcessingFrame = true;
    try {
      // Capture a frame from the camera
      final XFile imageFile = await _controller.takePicture();

      // Process the image with face detector
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      // Check if a face is detected
      if (faces.isNotEmpty) {
        // Face detected
        if (mounted) {
          setState(() {
            _isFaceDetected = true;
          });
        }
      } else {
        // No face detected
        if (mounted) {
          setState(() {
            _isFaceDetected = false;
          });
        }
      }

      // Delete the temporary image
      File(imageFile.path).deleteSync();
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed
    _controller.dispose();
    // Stop the timer
    _timer?.cancel();
    // Close the face detector
    _faceDetector.close();
    super.dispose();
  }

  Future<String> _takePicture() async {
    // Ensure the camera is initialized
    await _initializeControllerFuture;

    // Get the directory for storing images
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_camera';
    await Directory(dirPath).create(recursive: true);

    // Generate a unique file name
    final String filePath =
        '$dirPath/${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Take the picture
    final XFile image = await _controller.takePicture();
    // Copy the image to our custom location
    await File(image.path).copy(filePath);

    return filePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ambil Selfie',
          style: kTextStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kMainColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _isCameraReady) {
            // If the Future is complete, display the preview
            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(child: CameraPreview(_controller)),
                    Container(
                      height: 100,
                      color: Colors.black,
                      child: Center(
                        child: FloatingActionButton(
                          backgroundColor: _isFaceDetected
                              ? kMainColor
                              : Colors.grey,
                          child: const Icon(Icons.camera_alt),
                          onPressed: () async {
                            // Check if face is detected before allowing capture
                            if (!_isFaceDetected) {
                              toast(
                                'Wajah tidak terdeteksi. Posisikan wajah Anda dengan benar.',
                              );
                              return;
                            }

                            try {
                              // Display a loading indicator while we take the picture
                              toast('Mengambil foto...');

                              // Take the picture
                              final String imagePath = await _takePicture();

                              if (context.mounted) {
                                // Navigate to the add file screen with the captured image
                                const EmptyFileManagement().launch(context);
                                // Here you could also pass the image path to the next screen:
                                // AddFileManagement(imagePath: imagePath).launch(context);
                              }
                            } catch (e) {
                              // If an error occurs, log the error to the console.
                              toast('Error: $e');
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                // Face detection indicator overlay
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isFaceDetected
                            ? Colors.green.withOpacity(0.7)
                            : Colors.red.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isFaceDetected
                            ? 'Wajah Terdeteksi'
                            : 'Wajah Tidak Terdeteksi',
                        style: kTextStyle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Otherwise, display a loading indicator
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
