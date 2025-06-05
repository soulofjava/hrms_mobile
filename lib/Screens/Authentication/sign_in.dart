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
    setState(() {
      isLoading = true;
    });

    try {
      // Replace with your actual API endpoint
      final url = Uri.parse('$apiBaseUrl/auth/login');

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

        // Handle saving the token if your API returns one
        // You might want to use shared_preferences to store the token
        // For example: await SharedPreferences.getInstance().then((prefs) => prefs.setString('token', responseData['token']));

        // Show success toast
        Fluttertoast.showToast(
          msg: "Login successful",
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
          msg: errorData['message'] ?? "Login failed",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      // Network or other error
      Fluttertoast.showToast(
        msg: "An error occurred: ${e.toString()}",
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
          'Sign In',
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
              'Sign In now to begin an amazing journey',
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
                        hintText: 'example@email.com',
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
                      labelText: 'Password',
                      labelStyle: kTextStyle,
                      hintText: 'Enter password',
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
                      Text('Forgot Password?', style: kTextStyle).onTap(() {
                        const ForgotPassword().launch(context);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  isLoading
                      ? const CircularProgressIndicator(color: kMainColor)
                      : ButtonGlobal(
                          buttontext: 'Sign In',
                          buttonDecoration: kButtonDecoration.copyWith(
                            color: kMainColor,
                          ),
                          onPressed: () {
                            // Validate inputs
                            if (emailController.text.isEmpty) {
                              Fluttertoast.showToast(
                                msg: "Please enter your email",
                                backgroundColor: Colors.red,
                              );
                              return;
                            }
                            if (!emailController.text.contains('@')) {
                              Fluttertoast.showToast(
                                msg: "Please enter a valid email",
                                backgroundColor: Colors.red,
                              );
                              return;
                            }
                            if (passwordController.text.isEmpty) {
                              Fluttertoast.showToast(
                                msg: "Please enter your password",
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
                          text: 'Don\'t have an account? ',
                          style: kTextStyle.copyWith(color: kGreyTextColor),
                        ),
                        WidgetSpan(
                          child:
                              Text(
                                'Sign Up',
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
