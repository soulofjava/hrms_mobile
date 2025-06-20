// ignore_for_file: use_build_context_synchronously, use_super_parameters

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrms/Screens/Home/home_screen.dart';

// import '../../GlobalComponents/button_global.dart';
// import '../../GlobalComponents/purchase_model.dart';
import '../../constant.dart';
import 'on_board.dart';

// ignore_for_file: library_private_types_in_public_api
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await Future.delayed(const Duration(seconds: 2));

    defaultBlurRadius = 10.0;
    defaultSpreadRadius = 0.5;

    // Check if user is already logged in by looking for access token in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    
    finish(context);
    
    // If access token exists, navigate to HomeScreen, otherwise go to OnBoard
    if (accessToken != null && accessToken.isNotEmpty) {
      print('Found access token in SharedPreferences, navigating to HomeScreen');
      const HomeScreen().launch(context, isNewTask: true);
    } else {
      print('No access token found, navigating to OnBoard screen');
      const OnBoard().launch(context, isNewTask: true);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kMainColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 3),
            const Image(image: AssetImage('images/round_logo.png')),
            const Spacer(),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  'Version 1.0.0',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
