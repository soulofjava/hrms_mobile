// ignore_for_file: use_build_context_synchronously, use_super_parameters

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hrms/Screens/File%20Management/camera_screen.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../GlobalComponents/button_global.dart';
import '../../GlobalComponents/purchase_model.dart';
import '../../constant.dart';

// ignore_for_file: library_private_types_in_public_api
class EmptyFileManagement extends StatefulWidget {
  const EmptyFileManagement({Key? key}) : super(key: key);

  @override
  _EmptyFileManagementState createState() => _EmptyFileManagementState();
}

class _EmptyFileManagementState extends State<EmptyFileManagement> {
  // Function to open camera
  Future<void> _openCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        toast('Tidak ada kamera yang tersedia.');
        return;
      }

      // Open camera screen
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(cameras: cameras),
          ),
        );
      }
    } catch (e) {
      toast('Error saat membuka kamera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kMainColor,
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0.0,
        titleSpacing: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Presensi',
          maxLines: 2,
          style: kTextStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20.0),
          Expanded(
            child: Container(
              width: context.width(),
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Image(image: AssetImage('images/empty.png')),
                  const SizedBox(height: 20.0),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tidak ada data',
                        style: kTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Silakan lakukan presensi terlebih dahulu',
                        style: kTextStyle.copyWith(
                          color: kGreyTextColor,
                          fontSize: 14.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30.0),
                      // Rectangular button for presence with camera
                      SizedBox(
                        width: 200.0, // Set width for rectangular shape
                        child: ButtonGlobal(
                          buttontext: 'Presensi',
                          buttonDecoration: kButtonDecoration.copyWith(
                            color: kMainColor,
                            borderRadius: BorderRadius.circular(
                              10.0,
                            ), // Less rounded corners for a more rectangular look
                          ),
                          onPressed: () async {
                            bool isValid = await PurchaseModel()
                                .isActiveBuyer();
                            if (isValid) {
                              // Open camera for selfie instead of directly going to AddFileManagement
                              await _openCamera();
                            } else {
                              showLicense(context: context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
