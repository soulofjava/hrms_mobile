// ignore_for_file: library_private_types_in_public_api, use_super_parameters

import 'package:nb_utils/nb_utils.dart';
import 'package:flutter/material.dart';
import 'package:hrms/Screens/Authentication/sign_in.dart';

import '../../constant.dart';

class SelectType extends StatefulWidget {
  const SelectType({Key? key}) : super(key: key);

  @override
  _SelectTypeState createState() => _SelectTypeState();
}

class _SelectTypeState extends State<SelectType> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("images/bg.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Image(image: AssetImage("images/logo.png")),
                  const SizedBox(height: 100.0),
                  const Image(image: AssetImage("images/people.png")),
                  // Text(
                  //   'Select Your Role',
                  //   style: kTextStyle.copyWith(
                  //     fontSize: 20.0,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: kMainColor),
                        color: kMainColor,
                      ),
                      child: ListTile(
                        onTap: () {
                          const SignIn().launch(context);
                        },
                        // leading: const Image(
                        //   image: AssetImage('images/owner.png'),
                        // ),
                        title: Text(
                          'Mulai',
                          textAlign: TextAlign.center,
                          style: kTextStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // Hapus atau comment out bagian subtitle jika tidak ingin menampilkan teks pendukung
                        // subtitle: Text(
                        //   'Register your company & start attendance',
                        //   style: kTextStyle.copyWith(
                        //     color: kGreyTextColor,
                        //     fontSize: 12.0,
                        //   ),
                        // ),
                      ),
                    ),
                  ),

                  // Padding(
                  //   padding: const EdgeInsets.all(10.0),
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(20.0),
                  //       border: Border.all(color: kGreyTextColor),
                  //       color: Colors.white,
                  //     ),
                  //     child: ListTile(
                  //       onTap: () {
                  //         const SignIn().launch(context);
                  //       },
                  //       leading: const Image(
                  //         image: AssetImage('images/employee.png'),
                  //       ),
                  //       title: Text(
                  //         'Employee',
                  //         style: kTextStyle.copyWith(fontSize: 14.0),
                  //       ),
                  //       subtitle: Text(
                  //         'Register and start marking your attendance',
                  //         style: kTextStyle.copyWith(
                  //           color: kGreyTextColor,
                  //           fontSize: 12.0,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
