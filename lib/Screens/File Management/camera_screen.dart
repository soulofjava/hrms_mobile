// ignore_for_file: library_private_types_in_public_api, use_super_parameters

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hrms/Screens/File%20Management/empty_file_management.dart';
import 'package:hrms/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
  bool _isUploading = false;

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

    // Initialize the controller with high resolution
    _controller = CameraController(
      camera,
      ResolutionPreset.high, // Using high resolution instead of medium
      enableAudio: false, // Audio not needed for selfies
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

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
      print('CameraScreen Error processing camera image: $e');
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

  Future<void> _uploadAttendance(String imagePath) async {
    setState(() {
      _isUploading = true;
    });
    try {
      // Get token from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      print("CameraScreen tokenku: $token");

      if (token == null || token.isEmpty) {
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

      // Print API URL for debugging
      print("CameraScreen API URL: $apiBaseUrl/attendance/clock-in");

      // Check if file exists
      final file = File(imagePath);
      if (!await file.exists()) {
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

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/attendance/clock-in'),
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

      // Add status field
      request.fields['status'] = 'present';

      print("CameraScreen Request fields: ${request.fields}");
      print("CameraScreen Files to upload: ${request.files.length}");

      // Send the request with timeout
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

          toast(
            '$message: $data',
            bgColor: Colors.green,
            textColor: Colors.white,
          );

          if (context.mounted) {
            const EmptyFileManagement().launch(context);
          }
        } else {
          // Handle error
          Map<String, dynamic> errorData = {};
          try {
            errorData = json.decode(response.body);
            final errorMessage =
                errorData['meta']?['message'] ??
                errorData['message'] ??
                'Gagal mengirim presensi. Silakan coba lagi.';

            toast(errorMessage, bgColor: Colors.red, textColor: Colors.white);
          } catch (e) {
            print('CameraScreen Error parsing response: $e');
            toast(
              'Gagal mengirim presensi. Format respons tidak valid.',
              bgColor: Colors.red,
              textColor: Colors.white,
            );
          }
          print('CameraScreen API Error: ${response.body}');
        }
      } catch (e) {
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
      toast(
        'Terjadi kesalahan: ${e.toString()}',
        bgColor: Colors.red,
        textColor: Colors.white,
      );
      print('CameraScreen Exception during upload: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
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
                    // Using AspectRatio to maintain proper camera aspect ratio
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: CameraPreview(_controller),
                      ),
                    ),
                    Container(
                      height: 100,
                      color: Colors.black,
                      child: Center(
                        child: _isUploading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : FloatingActionButton(
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
                                    final String imagePath =
                                        await _takePicture();

                                    // Upload attendance with image
                                    await _uploadAttendance(imagePath);
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
