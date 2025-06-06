// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrms/Screens/Authentication/select_type.dart';
import 'package:hrms/Screens/Authentication/sign_in.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../constant.dart';

// ignore_for_file: library_private_types_in_public_api
class OnBoard extends StatefulWidget {
  const OnBoard({Key? key}) : super(key: key);

  @override
  _OnBoardState createState() => _OnBoardState();
}

class _OnBoardState extends State<OnBoard> {
  PageController pageController = PageController(initialPage: 0);
  int currentIndexPage = 0;
  String buttonText = 'Next';
  double percent = 0.34;

  List<Map<String, dynamic>> sliderList = [
    {
      "icon": 'images/onboard1.png',
      "title": 'Jaga keseimbangan kerja dan kehidupan yang sehat',
      "description":
          'Pertahankan keseimbangan antara pekerjaan dan kehidupan pribadi untuk kesehatan yang optimal.',
    },
    {
      "icon": 'images/onboard2.png',
      "title": 'Lacak pekerjaan Anda dan dapatkan hasil',
      "description":
          'Pantau progres pekerjaan secara real-time dan raih hasil terbaik.',
    },
    {
      "icon": 'images/onboard3.png',
      "title": 'Tetap teratur bersama tim',
      "description":
          'Bangun koordinasi dengan tim agar pekerjaan menjadi lebih terstruktur dan efisien.',
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFF),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFFFCF1F0)),
        backgroundColor: const Color(0xFFF0FDFF),
        elevation: 0.0,
        actions: [
          const SizedBox(width: 20.0),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton(
              onPressed: () {
                const SignIn().launch(context);
              },
              child: Text(
                'Lewati',
                style: GoogleFonts.dmSans(fontSize: 16.0, color: kTitleColor),
              ),
            ),
          ),
          const SizedBox(width: 30.0),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: SizedBox(
              height: context.height() - 100,
              width: context.width(),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    itemCount: sliderList.length,
                    controller: pageController,
                    onPageChanged: (int index) {
                      setState(() {
                        switch (index) {
                          case 0:
                            {
                              percent = 0.33;
                              currentIndexPage = 0;
                            }
                            break;
                          case 1:
                            {
                              percent = 0.66;
                              currentIndexPage = 1;
                            }
                            break;
                          case 2:
                            {
                              percent = 1.00;
                              currentIndexPage = 2;
                            }
                            break;
                        }
                      });
                    },
                    itemBuilder: (_, index) {
                      return Column(
                        children: [
                          Image.asset(
                            sliderList[index]['icon'],
                            fit: BoxFit.fill,
                            width: context.width(),
                          ),
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30.0),
                                  topRight: Radius.circular(30.0),
                                ),
                                color: Colors.white,
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 20.0,
                                      right: 30.0,
                                      top: 15.0,
                                      bottom: 15.0,
                                    ),
                                    child: Text(
                                      sliderList[index]['title'].toString(),
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.jost(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 30.0,
                                      right: 20.0,
                                    ),
                                    // ignore: sized_box_for_whitespace
                                    child: Container(
                                      width: context.width(),
                                      child: Text(
                                        sliderList[index]['description']
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 5,
                                        style: GoogleFonts.jost(
                                          fontSize: 15.0,
                                          color: kGreyTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ignore: sized_box_for_whitespace
                        ],
                      );
                    },
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DotIndicator(
                          currentDotSize: 15,
                          dotSize: 6,
                          pageController: pageController,
                          pages: sliderList,
                          indicatorColor: kMainColor,
                          unselectedIndicatorColor: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularPercentIndicator(
                          radius: 80.0,
                          lineWidth: 3.0,
                          progressColor: kMainColor,
                          percent: percent,
                          animation: true,
                          center: GestureDetector(
                            onTap: () {
                              setState(() {
                                currentIndexPage < 2
                                    ? pageController.nextPage(
                                        duration: const Duration(
                                          microseconds: 3000,
                                        ),
                                        curve: Curves.bounceInOut,
                                      )
                                    : Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SelectType(),
                                        ),
                                      );
                              });
                            },
                            child: const CircleAvatar(
                              radius: 35.0,
                              backgroundColor: kMainColor,
                              child: Center(
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                ),
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
          ),
        ],
      ),
    );
  }
}
