// ignore_for_file: library_private_types_in_public_api, use_super_parameters, depend_on_referenced_packages

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hrms/Kasbon/kasbon_form.dart';
import 'package:hrms/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class KasbonScreen extends StatefulWidget {
  const KasbonScreen({Key? key}) : super(key: key);

  @override
  _KasbonScreenState createState() => _KasbonScreenState();
}

class _KasbonScreenState extends State<KasbonScreen> {
  bool _isLoading = false;
  List<dynamic> _kasbonList = [];
  String? _errorMessage;

  // Tambahkan variable untuk maximum limit
  Map<String, dynamic>? _maximumLimitData;
  bool _isLoadingLimit = false;

  @override
  void initState() {
    super.initState();
    _fetchKasbonData();
    _fetchMaximumLimit();
  }

  // Fungsi baru untuk mengambil maximum limit
  Future<void> _fetchMaximumLimit() async {
    setState(() {
      _isLoadingLimit = true;
    });

    try {
      // Get the token from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingLimit = false;
        });
        return;
      }

      // Make API request
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/kasbon/maximum-limit'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Timeout. Server tidak merespon.');
            },
          );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Maximum limit response: $responseData');

        if (responseData['success'] == true) {
          setState(() {
            _maximumLimitData = responseData['data'];
            _isLoadingLimit = false;
          });
        } else {
          setState(() {
            _isLoadingLimit = false;
          });
        }
      } else {
        setState(() {
          _isLoadingLimit = false;
        });
        print('Error fetching maximum limit: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoadingLimit = false;
      });
      print('Exception in fetching maximum limit: $e');
    }
  }

  Future<void> _fetchKasbonData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the token from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sesi login telah berakhir. Silakan login kembali.';
        });
        return;
      }

      // Make API request
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/kasbon/requests'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Timeout. Server tidak merespon.');
            },
          );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Kasbon history response: $responseData');

        // Periksa format responseData yang benar
        if (responseData['success'] == true) {
          setState(() {
            _kasbonList = responseData['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = responseData['message'] ?? 'Terjadi kesalahan.';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${response.statusCode}';
        });
        print('Error fetching kasbon data: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
      print('Exception in fetching kasbon data: $e');
    }
  }

  // Format currency
  String formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';

    try {
      final formatter = NumberFormat.currency(
        locale: 'id',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(double.parse(amount.toString()));
    } catch (e) {
      print('Error formatting currency: $e');
      return 'Rp $amount';
    }
  }

  // Format date in Indonesian format using intl package
  // Format date in Indonesian format with time using intl package
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';

    try {
      final DateTime date = DateTime.parse(dateString);

      // Set locale to Indonesian and format the date with time
      Intl.defaultLocale = 'id';

      // Format: "Senin, 1 Januari 2023 09:30 WIB"
      final DateFormat formatter = DateFormat('EEEE, d MMMM yyyy HH:mm');
      return '${formatter.format(date)} WIB';
    } catch (e) {
      print('Error formatting date: $e');
      return dateString;
    }
  }

  // Get status color
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get status text in Indonesian
  String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  // Widget untuk menampilkan informasi maximum limit
  Widget _buildMaximumLimitInfo() {
    if (_isLoadingLimit) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_maximumLimitData == null) {
      return Container();
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kMainColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Limit Kasbon',
              style: kTextStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kMainColor,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow('Periode:', _maximumLimitData?['period'] ?? '-'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Hari Kerja:',
              '${_maximumLimitData?['attended_days'] ?? 0} / ${_maximumLimitData?['total_work_days'] ?? 0} hari',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Gaji Bulan Ini:',
              formatCurrency(_maximumLimitData?['month_salary']),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Gaji Diperoleh:',
              formatCurrency(_maximumLimitData?['earned_salary_so_far']),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Limit Maksimum:',
              formatCurrency(_maximumLimitData?['maximum_limit']),
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainColor,
      appBar: AppBar(
        title: Text(
          'Pengajuan Kasbon',
          style: kTextStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kMainColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchKasbonData();
              _fetchMaximumLimit();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20.0),
          Expanded(
            child: Container(
              width: context.width(),
              padding: const EdgeInsets.only(top: 20.0),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                color: Colors.white,
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: kTextStyle.copyWith(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchKasbonData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kMainColor,
                              ),
                              child: Text(
                                'Coba Lagi',
                                style: kTextStyle.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Tampilkan informasi maximum limit
                        _buildMaximumLimitInfo(),

                        // Title untuk riwayat kasbon
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Riwayat Pengajuan',
                                style: kTextStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_kasbonList.length} Pengajuan',
                                style: kTextStyle.copyWith(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tampilkan daftar kasbon
                        Expanded(
                          child: _kasbonList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Tidak ada data kasbon',
                                        style: kTextStyle.copyWith(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _fetchKasbonData,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kMainColor,
                                        ),
                                        child: Text(
                                          'Refresh',
                                          style: kTextStyle.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchKasbonData,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    itemCount: _kasbonList.length,
                                    itemBuilder: (context, index) {
                                      final kasbon = _kasbonList[index];
                                      return Card(
                                        elevation: 3,
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Pengajuan #${kasbon['id'] ?? '-'}',
                                                    style: kTextStyle.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: getStatusColor(
                                                        kasbon['status'] ??
                                                            'pending',
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      getStatusText(
                                                        kasbon['status'] ??
                                                            'Pending',
                                                      ),
                                                      style: kTextStyle
                                                          .copyWith(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(height: 24),
                                              _buildInfoRow(
                                                'Tanggal Pengajuan:',
                                                formatDate(
                                                  kasbon['request_date'] ??
                                                      kasbon['created_at'],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              _buildInfoRow(
                                                'Jumlah:',
                                                formatCurrency(
                                                  kasbon['amount'],
                                                ),
                                              ),
                                              if (kasbon['admin_fee'] != null &&
                                                  kasbon['admin_fee']
                                                          .toString() !=
                                                      '0' &&
                                                  kasbon['admin_fee']
                                                          .toString() !=
                                                      '0.00')
                                                Column(
                                                  children: [
                                                    const SizedBox(height: 8),
                                                    _buildInfoRow(
                                                      'Biaya Admin:',
                                                      formatCurrency(
                                                        kasbon['admin_fee'],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (kasbon['transfer_fee'] !=
                                                      null &&
                                                  kasbon['transfer_fee']
                                                          .toString() !=
                                                      '0' &&
                                                  kasbon['transfer_fee']
                                                          .toString() !=
                                                      '0.00')
                                                Column(
                                                  children: [
                                                    const SizedBox(height: 8),
                                                    _buildInfoRow(
                                                      'Biaya Transfer:',
                                                      formatCurrency(
                                                        kasbon['transfer_fee'],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (kasbon['notes'] != null &&
                                                  kasbon['notes']
                                                      .toString()
                                                      .isNotEmpty)
                                                Column(
                                                  children: [
                                                    const SizedBox(height: 8),
                                                    _buildInfoRow(
                                                      'Catatan:',
                                                      kasbon['notes'],
                                                    ),
                                                  ],
                                                ),
                                              if (kasbon['status']
                                                          ?.toLowerCase() ==
                                                      'approved' &&
                                                  kasbon['approved_at'] != null)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 8),
                                                    _buildInfoRow(
                                                      'Disetujui Pada:',
                                                      formatDate(
                                                        kasbon['approved_at'],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Tampilkan dialog jika belum ada data limit
          if (_maximumLimitData == null) {
            toast('Memuat informasi limit kasbon...', bgColor: Colors.orange);
            await _fetchMaximumLimit();
            if (_maximumLimitData == null) {
              toast('Gagal memuat informasi limit kasbon', bgColor: Colors.red);
              return;
            }
          }

          // Navigate to KasbonFormScreen
          if (context.mounted) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => KasbonFormScreen(
                  maximumLimit: double.parse(
                    _maximumLimitData?['maximum_limit'].toString() ?? '0',
                  ),
                ),
              ),
            );

            // Refresh data if returning with success result
            if (result == true) {
              _fetchKasbonData();
              _fetchMaximumLimit();
            }
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Ajukan Kasbon',
          style: kTextStyle.copyWith(color: Colors.white),
        ),
        backgroundColor: kMainColor,
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isRejection = false,
    bool isHighlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: kTextStyle.copyWith(color: Colors.grey[700], fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: kTextStyle.copyWith(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
              color: isRejection
                  ? Colors.red
                  : isHighlighted
                  ? kMainColor
                  : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
