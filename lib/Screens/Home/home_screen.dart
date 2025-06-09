// ignore_for_file: deprecated_member_use, use_super_parameters

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hrms/Kasbon/kasbon.dart';
import 'package:hrms/Screens/Authentication/profile_screen.dart';
import 'package:hrms/Screens/Authentication/sign_in.dart';
import 'package:hrms/Screens/Expense%20Management/management_screen.dart';
import 'package:hrms/Screens/Camera/camera_screen.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constant.dart';

// ignore_for_file: library_private_types_in_public_api
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isChecked = false;
  bool isLoggingOut = false;
  String userName = 'User';
  String userEmail = 'user@example.com';
  String userRole = '';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // Helper method to open camera
  Future<void> _openCameraWithStatus(String status) async {
    try {
      // Get available cameras
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        toast('Tidak ada kamera yang tersedia.');
        return;
      }

      // Navigate to CameraScreen with the given status
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CameraScreen(cameras: cameras, status: status),
          ),
        );
      }
    } catch (e) {
      toast('Error saat membuka kamera: $e');
    }
  }

  // Load user data from SharedPreferences
  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      final roles = prefs.getString('roles');

      if (userJson != null && userJson.isNotEmpty) {
        final userData = jsonDecode(userJson);
        setState(() {
          userName = userData['name'] ?? 'User';
          userEmail = userData['email'] ?? 'user@example.com';
        });

        print('Loaded user data: $userData');
      }

      if (roles != null && roles.isNotEmpty) {
        final rolesList = jsonDecode(roles);
        if (rolesList is List && rolesList.isNotEmpty) {
          setState(() {
            userRole = rolesList[0].toString();
          });
        }

        print('Loaded roles: $rolesList');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Function to handle logout
  Future<void> logoutUser() async {
    try {
      setState(() {
        isLoggingOut = true;
      });

      // Get the access token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null || accessToken.isEmpty) {
        // If no token is found, just clear preferences and navigate to login
        await prefs.clear();

        Fluttertoast.showToast(
          msg: "Berhasil keluar",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        const SignIn().launch(context, isNewTask: true);
        return;
      }

      // Make API request to logout
      final url = Uri.parse('$apiBaseUrl/logout');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      // Clear SharedPreferences regardless of response
      await prefs.clear();

      if (response.statusCode == 200) {
        // Successfully logged out
        Fluttertoast.showToast(
          msg: "Berhasil keluar",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        // Log the error but still proceed with local logout
        print('Logout API error: ${response.body}');
        Fluttertoast.showToast(
          msg: "Berhasil keluar dari aplikasi",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }

      // Navigate to login screen
      const SignIn().launch(context, isNewTask: true);
    } catch (e) {
      // Handle network or other errors
      print('Logout error: $e');

      // Clear SharedPreferences anyway to ensure user can logout locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Fluttertoast.showToast(
        msg: "Berhasil keluar dari aplikasi",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Navigate to login screen
      const SignIn().launch(context, isNewTask: true);
    } finally {
      setState(() {
        isLoggingOut = false;
      });
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
        // title: Text(
        //   'HRM & Payroll Management',
        //   maxLines: 2,
        //   style: kTextStyle.copyWith(color: Colors.white, fontSize: 16.0),
        // ),
        // actions: const [
        //   Image(image: AssetImage('images/notificationicon.png')),
        // ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            Column(
              children: [
                Container(
                  height: context.height() / 4,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30.0),
                      bottomRight: Radius.circular(30.0),
                    ),
                    color: Colors.white,
                  ),
                  child: Center(
                    child:
                        Column(
                          children: [
                            const SizedBox(height: 10.0),
                            const CircleAvatar(
                              radius: 60.0,
                              backgroundColor: kMainColor,
                              backgroundImage: AssetImage('images/emp1.png'),
                            ),
                            const SizedBox(height: 10.0),
                            Text(
                              userName,
                              style: kTextStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userEmail,
                              style: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                          ],
                        ).onTap(() {
                          const ProfileScreen().launch(context);
                        }),
                  ),
                ),
              ],
            ),
            ListTile(
              onTap: () {
                // Call the logout function
                logoutUser();
              },
              leading: const Icon(
                FontAwesomeIcons.signOutAlt,
                color: kGreyTextColor,
              ),
              title: Text(
                'Keluar',
                style: kTextStyle.copyWith(color: kGreyTextColor),
              ),
              trailing: isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: kMainColor,
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_ios, color: kGreyTextColor),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20.0),
            Container(
              height: context.height(),
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          elevation: 2.0,
                          child: GestureDetector(
                            onTap: () => _openCameraWithStatus('present'),
                            child: Container(
                              width: context.width(),
                              padding: const EdgeInsets.all(10.0),
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Color(0xFF4ACDF9),
                                    width: 3.0,
                                  ),
                                ),
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'images/arrow_16559130.png',
                                    width:
                                        60, // sesuaikan nilai width jika ingin lebih kecil/besar
                                    height:
                                        60, // sesuaikan nilai height jika ingin lebih kecil/besar
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Presensi Masuk',
                                    textAlign: TextAlign
                                        .center, // memastikan teks rata tengah
                                    maxLines: 2,
                                    style: kTextStyle.copyWith(
                                      color: kTitleColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20.0),
                      Expanded(
                        child: Material(
                          elevation: 2.0,
                          child: GestureDetector(
                            onTap: () => _openCameraWithStatus(''),
                            child: Container(
                              width: context.width(),
                              padding: const EdgeInsets.all(10.0),
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Color(0xFF02B984),
                                    width: 3.0,
                                  ),
                                ),
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'images/arrow_16557141.png',
                                    width: 60,
                                    height: 60,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Presensi Keluar',
                                    textAlign: TextAlign
                                        .center, // memastikan teks rata tengah
                                    maxLines: 2,
                                    style: kTextStyle.copyWith(
                                      color: kTitleColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          elevation: 2.0,
                          child: GestureDetector(
                            onTap: () {
                              const KasbonScreen().launch(context);
                            },
                            child: Container(
                              width: context.width(),
                              padding: const EdgeInsets.all(10.0),
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Color(0xFF7C69EE),
                                    width: 3.0,
                                  ),
                                ),
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'images/bill_7325300.png',
                                    width:
                                        60, // sesuaikan nilai width jika ingin lebih kecil/besar
                                    height:
                                        60, // sesuaikan nilai height jika ingin lebih kecil/besar
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Kasbon',
                                    textAlign: TextAlign
                                        .center, // memastikan teks rata tengah
                                    maxLines: 2,
                                    style: kTextStyle.copyWith(
                                      color: kTitleColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20.0),
                      Expanded(
                        child: Material(
                          elevation: 2.0,
                          child: GestureDetector(
                            onTap: () {
                              const ExpenseManagementScreen().launch(context);
                            },
                            child: Container(
                              width: context.width(),
                              padding: const EdgeInsets.all(10.0),
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Color(0xFFFD72AF),
                                    width: 3.0,
                                  ),
                                ),
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Image(
                                    image: AssetImage(
                                      'images/expensemanagement.png',
                                    ),
                                  ),
                                  Text(
                                    'Expense Management',
                                    style: kTextStyle.copyWith(
                                      color: kTitleColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
