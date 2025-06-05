// ignore_for_file: use_build_context_synchronously

import 'package:hrms/Screens/NOC%20Certificate/add_certificate.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter/material.dart';

import '../../GlobalComponents/button_global.dart';
import '../../GlobalComponents/purchase_model.dart';
import '../../constant.dart';

// ignore_for_file: library_private_types_in_public_api
class EmptyCertificate extends StatefulWidget {
  const EmptyCertificate({Key? key}) : super(key: key);

  @override
  _EmptyCertificateState createState() => _EmptyCertificateState();
}

class _EmptyCertificateState extends State<EmptyCertificate> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool isValid = await PurchaseModel().isActiveBuyer();
          if (isValid) {
            const AddCertificate().launch(context);
          } else {
            showLicense(context: context);
          }
        },
        backgroundColor: kMainColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      resizeToAvoidBottomInset: false,
      backgroundColor: kMainColor,
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0.0,
        titleSpacing: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Empty Certificate',
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
                    children: [
                      Text(
                        'No Data',
                        style: kTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        ),
                      ),
                      Text(
                        'Add your certificate',
                        style: kTextStyle.copyWith(color: kGreyTextColor),
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
