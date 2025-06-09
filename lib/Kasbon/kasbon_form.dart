// ignore_for_file: library_private_types_in_public_api, use_super_parameters, depend_on_referenced_packages

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class KasbonFormScreen extends StatefulWidget {
  final double maximumLimit;

  const KasbonFormScreen({Key? key, required this.maximumLimit})
    : super(key: key);

  @override
  _KasbonFormScreenState createState() => _KasbonFormScreenState();
}

class _KasbonFormScreenState extends State<KasbonFormScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  bool _isAmountValid = false;
  String _formattedAmount = '';

  // Tambahkan variabel untuk format mata uang
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: '',
    decimalDigits: 0,
  );

  // Tambahkan method untuk memformat nilai input
  void _formatCurrencyInput() {
    String text = _amountController.text;

    if (text.isEmpty) return;

    // Hapus semua karakter non-digit
    String digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      _amountController.clear();
      return;
    }

    // Parse ke double
    double value = double.parse(digitsOnly);

    // Format dengan currency formatter tanpa simbol
    String formatted = _currencyFormatter.format(value);

    // Update controller dengan nilai yang diformat
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    // Validasi jumlah
    setState(() {
      _isAmountValid = value > 0 && value <= widget.maximumLimit;
    });
  }

  @override
  void initState() {
    super.initState();
    // Ganti listener lama dengan yang baru
    // _amountController.addListener(_formatCurrencyInput);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // Format currency
  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Validate and format amount on change
  void _onAmountChanged(String value) {
    // Remove non-digits
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      setState(() {
        _isAmountValid = false;
        _formattedAmount = '';
      });
      return;
    }

    double amount = double.parse(digitsOnly);

    setState(() {
      _isAmountValid = amount > 0 && amount <= widget.maximumLimit;
      _formattedAmount = formatCurrency(amount);
    });
  }

  // Submit kasbon
  Future<void> _submitKasbon() async {
    if (!_isAmountValid) return;

    setState(() {
      _isSubmitting = true;
    });
    try {
      // Get amount as double from controller
      String digitsOnly = _amountController.text.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );
      double amount = double.parse(digitsOnly);

      // Get token from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        toast(
          'Sesi login telah berakhir. Silakan login kembali.',
          bgColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Create request body
      final Map<String, dynamic> requestBody = {
        'amount': amount.toString(),
        // 'reason': reason,
      };

      // Make API request
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/kasbon/requests'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Timeout. Server tidak merespon.');
            },
          );

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 201) {
        // Status 201 Created menandakan success
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // Ambil ID dari response
          final String kasbonId = responseData['data']?['id']?.toString() ?? '';

          // Show success dialog
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Pengajuan Berhasil',
                      style: kTextStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pengajuan kasbon Anda telah berhasil diajukan.'),
                    const SizedBox(height: 16),
                    _buildInfoRow('ID Pengajuan:', '#$kasbonId'),
                    const SizedBox(height: 4),
                    _buildInfoRow('Jumlah:', formatCurrency(amount)),
                    const SizedBox(height: 4),
                    _buildInfoRow('Status:', 'Menunggu Persetujuan'),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(
                        context,
                        true,
                      ); // Return to previous screen with success result
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                    ),
                    child: Text(
                      'OK',
                      style: kTextStyle.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }
        } else {
          toast(
            responseData['message'] ?? 'Pengajuan kasbon berhasil',
            bgColor: Colors.green,
            textColor: Colors.white,
          );
          // Return to previous screen
          if (context.mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        // Error handling
        try {
          final responseData = json.decode(response.body);
          toast(
            responseData['message'] ??
                'Gagal mengajukan kasbon. Status: ${response.statusCode}',
            bgColor: Colors.red,
            textColor: Colors.white,
          );
        } catch (e) {
          toast(
            'Gagal mengajukan kasbon. Status: ${response.statusCode}',
            bgColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      toast(
        'Terjadi kesalahan: $e',
        bgColor: Colors.red,
        textColor: Colors.white,
      );
      print('Error submitting kasbon: $e');
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: kTextStyle.copyWith(color: Colors.grey[700], fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: kTextStyle.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainColor,
      appBar: AppBar(
        title: Text(
          'Ajukan Kasbon',
          style: kTextStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kMainColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Information Card
                    Card(
                      elevation: 3,
                      color: kMainColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: kMainColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Informasi Limit',
                                  style: kTextStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: kMainColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Anda dapat mengajukan kasbon maksimal sebesar:',
                              style: kTextStyle.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatCurrency(widget.maximumLimit),
                              style: kTextStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: kMainColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Amount Input
                    Text(
                      'Jumlah Kasbon',
                      style: kTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          onChanged: _onAmountChanged,
                          decoration: InputDecoration(
                            hintText: 'Masukkan jumlah kasbon',
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: kMainColor.withOpacity(0.2),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Rp',
                                style: kTextStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: kMainColor,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: kMainColor),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        if (_formattedAmount.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Jumlah: $_formattedAmount',
                              style: kTextStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _isAmountValid ? kMainColor : Colors.red,
                              ),
                            ),
                          ),
                        if (!_isAmountValid &&
                            _amountController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Jumlah harus lebih dari 0 dan tidak melebihi ${formatCurrency(widget.maximumLimit)}',
                              style: kTextStyle.copyWith(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Reason Input
                    // Text(
                    //   'Alasan Pengajuan (Opsional)',
                    //   style: kTextStyle.copyWith(
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: 16,
                    //   ),
                    // ),

                    // const SizedBox(height: 8),
                    // TextFormField(
                    //   controller: _reasonController,
                    //   maxLines: 4,
                    //   decoration: InputDecoration(
                    //     hintText: 'Masukkan alasan pengajuan kasbon',
                    //     filled: true,
                    //     fillColor: Colors.grey[100],
                    //     enabledBorder: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(8),
                    //       borderSide: BorderSide(color: Colors.grey[300]!),
                    //     ),
                    //     focusedBorder: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(8),
                    //       borderSide: const BorderSide(color: kMainColor),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isAmountValid && !_isSubmitting
                            ? _submitKasbon
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kMainColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Ajukan Kasbon',
                                style: kTextStyle.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
