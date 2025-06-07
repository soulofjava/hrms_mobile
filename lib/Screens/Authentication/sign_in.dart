// ignore_for_file: library_private_types_in_public_api, use_super_parameters

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hrms/GlobalComponents/button_global.dart';
import 'package:hrms/Screens/Authentication/forgot_password.dart';
import 'package:hrms/Screens/Authentication/sign_up.dart';
import 'package:hrms/Screens/Home/home_screen.dart';
import 'package:hrms/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isChecked = false;
  bool isLoading = false;
  bool obscurePassword = true; // Added for password visibility toggle

  // Function to handle API sign in
  Future<void> signInWithApi() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);
      
      // Replace with your actual API endpoint
      final url = Uri.parse('$apiBaseUrl/login');

      // Prepare the request body
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Successfully logged in
        final responseData = json.decode(response.body);
        
        // Print response for debugging
        print('Login response: ${response.body}');
        
        // Get shared preferences instance
        final prefs = await SharedPreferences.getInstance();
        
        // Check if the response has the expected format with 'data' field
        if (responseData['data'] != null) {
          final data = responseData['data'];
          
          // Store access token
          if (data['access_token'] != null) {
            await prefs.setString('access_token', data['access_token']);
            print('Saved access_token to SharedPreferences');
          }
          
          // Store token type
          if (data['token_type'] != null) {
            await prefs.setString('token_type', data['token_type']);
            print('Saved token_type to SharedPreferences');
          }
          
          // Store user data as JSON string
          if (data['user'] != null) {
            await prefs.setString('user', json.encode(data['user']));
            print('Saved user data to SharedPreferences');
          }
          
          // Store roles as JSON string
          if (data['Role'] != null) {
            await prefs.setString('roles', json.encode(data['Role']));
            print('Saved roles to SharedPreferences');
          }
        } 
        // If the response doesn't have a 'data' field, try to parse it directly
        else {
          // Store access token
          if (responseData['access_token'] != null) {
            await prefs.setString('access_token', responseData['access_token']);
            print('Saved access_token to SharedPreferences (direct)');
          }
          
          // Store token type
          if (responseData['token_type'] != null) {
            await prefs.setString('token_type', responseData['token_type']);
            print('Saved token_type to SharedPreferences (direct)');
          }
          
          // Store user data as JSON string
          if (responseData['user'] != null) {
            await prefs.setString('user', json.encode(responseData['user']));
            print('Saved user data to SharedPreferences (direct)');
          }
          
          // Store roles as JSON string
          if (responseData['Role'] != null) {
            await prefs.setString('roles', json.encode(responseData['Role']));
            print('Saved roles to SharedPreferences (direct)');
          }
        }

        // Show success toast
        Fluttertoast.showToast(
          msg: "Login berhasil",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Navigate to home screen
        const HomeScreen().launch(context);
      } else {
        // Login failed
        final errorData = json.decode(response.body);
        Fluttertoast.showToast(
          msg: errorData['message'] ?? "Login gagal",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      // Network or other error
      Fluttertoast.showToast(
        msg: "Terjadi kesalahan: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Masuk',
          style: kTextStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Masuk sekarang untuk memulai perjalanan luar biasa',
              style: kTextStyle.copyWith(color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
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
                  SizedBox(
                    height: 60.0,
                    child: AppTextField(
                      textFieldType: TextFieldType.EMAIL,
                      controller: emailController,
                      enabled: true,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'contoh@email.com',
                        labelStyle: kTextStyle,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  // Custom password field with visibility toggle
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi',
                      labelStyle: kTextStyle,
                      hintText: 'Masukkan kata sandi',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: kGreyTextColor,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      // Transform.scale(
                      //   scale: 0.8,
                      //   child: CupertinoSwitch(
                      //     value: isChecked,
                      //     thumbColor: kGreyTextColor,
                      //     onChanged: (bool value) {
                      //       setState(() {
                      //         isChecked = value;
                      //       });
                      //     },
                      //   ),
                      // ),
                      // Text('Save Me', style: kTextStyle),
                      const Spacer(),
                      Text('Lupa Kata Sandi?', style: kTextStyle).onTap(() {
                        const ForgotPassword().launch(context);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  isLoading
                      ? const CircularProgressIndicator(color: kMainColor)
                      : ButtonGlobal(
                          buttontext: 'Masuk',
                          buttonDecoration: kButtonDecoration.copyWith(
                            color: kMainColor,
                          ),
                          onPressed: () {
                            // Validate inputs
                            if (emailController.text.isEmpty) {
                              Fluttertoast.showToast(
                                msg: "Silakan masukkan email Anda",
                                backgroundColor: Colors.red,
                              );
                              return;
                            }
                            if (!emailController.text.contains('@')) {
                              Fluttertoast.showToast(
                                msg: "Silakan masukkan email yang valid",
                                backgroundColor: Colors.red,
                              );
                              return;
                            }
                            if (passwordController.text.isEmpty) {
                              Fluttertoast.showToast(
                                msg: "Silakan masukkan kata sandi Anda",
                                backgroundColor: Colors.red,
                              );
                              return;
                            }

                            // Call the sign in API function
                            signInWithApi();
                          },
                        ),
                  const SizedBox(height: 20.0),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Belum punya akun? ',
                          style: kTextStyle.copyWith(color: kGreyTextColor),
                        ),
                        WidgetSpan(
                          child:
                              Text(
                                'Daftar',
                                style: kTextStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: kMainColor,
                                ),
                              ).onTap(() {
                                const SignUp().launch(context);
                              }),
                        ),
                      ],
                    ),
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
