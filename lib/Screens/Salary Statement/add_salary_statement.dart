// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:hrms/GlobalComponents/button_global.dart';
import 'package:hrms/Screens/Salary%20Statement/salary_statement_list.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../constant.dart';

// ignore_for_file: library_private_types_in_public_api
class AddSalaryStatement extends StatefulWidget {
  const AddSalaryStatement({Key? key}) : super(key: key);

  @override
  _AddSalaryStatementState createState() => _AddSalaryStatementState();
}

class _AddSalaryStatementState extends State<AddSalaryStatement> {
  List<String> userChecked = [];
  String designation = 'Designer';
  String gender = 'Full Time';
  bool selection = false;
  final dateController = TextEditingController();

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  DropdownButton<String> getDesignation() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in designations) {
      var item = DropdownMenuItem(value: des, child: Text(des));
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: designation,
      onChanged: (value) {
        setState(() {
          designation = value!;
        });
      },
    );
  }

  DropdownButton<String> getGender() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String gender in employeeType) {
      var item = DropdownMenuItem(value: gender, child: Text(gender));
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: gender,
      onChanged: (value) {
        setState(() {
          gender = value!;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainColor,
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Add Salary Statement',
          style: kTextStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                        flex: 1,
                        child: Image.asset('images/employeeaddimage.png'),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            AppTextField(
                              textFieldType: TextFieldType.NAME,
                              readOnly: true,
                              onTap: () async {
                                var date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(2100),
                                );
                                dateController.text = date.toString().substring(
                                  0,
                                  10,
                                );
                              },
                              controller: dateController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                suffixIcon: Icon(
                                  Icons.date_range_rounded,
                                  color: kGreyTextColor,
                                ),
                                labelText: 'Select Date',
                                hintText: '11/09/2021',
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            AppTextField(
                              textFieldType: TextFieldType.PHONE,
                              decoration: const InputDecoration(
                                labelText: 'Basic Pay',
                                hintText: '\$1000',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  AppTextField(
                    textFieldType: TextFieldType.NAME,
                    decoration: const InputDecoration(
                      labelText: 'Employee Name',
                      hintText: 'MaanTheme',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                    height: 60.0,
                    child: FormField(
                      builder: (FormFieldState<dynamic> field) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelText: 'Employee Type',
                            labelStyle: kTextStyle,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: getGender(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                    height: 60.0,
                    child: FormField(
                      builder: (FormFieldState<dynamic> field) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelText: 'Select Designation',
                            labelStyle: kTextStyle,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: getDesignation(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  AppTextField(
                    textFieldType: TextFieldType.PHONE,
                    decoration: const InputDecoration(
                      labelText: 'Provident Fund',
                      hintText: '\$00.00',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  AppTextField(
                    textFieldType: TextFieldType.PHONE,
                    decoration: const InputDecoration(
                      labelText: 'Gross Salary',
                      hintText: '\$00.00',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  ButtonGlobal(
                    buttontext: 'Save',
                    buttonDecoration: kButtonDecoration.copyWith(
                      color: kMainColor,
                    ),
                    onPressed: () {
                      const SalaryStatementList().launch(context);
                    },
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
