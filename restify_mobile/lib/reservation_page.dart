import 'package:flutter/material.dart';
import 'package:restify/midtrans_page.dart';
import 'payment_success_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'image_utils.dart';

const String _baseUrl = Config.baseUrl;

class ReservationPage extends StatefulWidget {
  final Map<String, dynamic> hotel;
  final String selectedRoom;

  const ReservationPage({
    super.key,
    required this.hotel,
    required this.selectedRoom,
  });

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  @override
    void initState() {
      super.initState();

      loadUserData();
    }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    nameController.text =
        prefs.getString('name') ?? '';

    emailController.text =
        prefs.getString('email') ?? '';

    phoneController.text =
        prefs.getString('phone') ?? '';

    setState(() {});
  }

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  DateTime? checkInDate;
  DateTime? checkOutDate;

  bool dateError = false;
  bool isSubmitting = false;
  String? submitError;

  int guest = 1;

  String paymentMethod = "QRIS";

  int get roomPrice {
    final rawPrice = widget.hotel["price"] ?? "Rp0";

    return int.tryParse(
          rawPrice.toString().replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
  }

  String formatCurrency(int value) {
    final text = value.toString();

    final buffer = StringBuffer();

    int counter = 0;

    for (int i = text.length - 1; i >= 0; i--) {
      buffer.write(text[i]);
      counter++;

      if (counter % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }

    return "Rp${buffer.toString().split('').reversed.join()}";
  }

  int get maxGuests {
    final capacity = int.tryParse(
      (widget.hotel["room_capacity"] ?? "1").toString(),
    );

    if (capacity == null || capacity < 1) return 1;
    return capacity;
  }

  String formatDateForApi(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> createBooking() async {
    setState(() {
      isSubmitting = true;
      submitError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          isSubmitting = false;
          submitError = "Sesi login habis. Silakan login kembali.";
        });
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/user/booking'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'room_id': widget.hotel['room_id'],
          'check_in_date': formatDateForApi(checkInDate!),
          'check_out_date': formatDateForApi(checkOutDate!),
          'guests': guest,
          'extra_bed': false,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      if (response.statusCode == 201) {
        final bookingId = data['data']['booking_id'];

        await createPayment(bookingId);
      } else {
        setState(() {
          submitError = data['message'] ?? "Gagal membuat pemesanan";
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        submitError = "Tidak dapat terhubung ke server";
      });
    }
  }

  Future<void> createPayment(int bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/user/pay/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      debugPrint(response.statusCode.toString());
      debugPrint(response.body.toString());

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final snapToken = data['snap_token'];

        if (!mounted) return; final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MidtransPage(
              snapToken: snapToken,
            ),
          ),
        );

        if (result == true) {
          await checkPaymentStatus(bookingId);
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> checkPaymentStatus(int bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/booking/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      final data = jsonDecode(response.body);

      debugPrint(data.toString());

      if (response.statusCode == 200) {
        final paymentStatus =
            data['data']['payment_status'];

        if (paymentStatus == 'paid') {
          if (!mounted) return; Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessPage(
                hotel: widget.hotel,
                selectedRoom: widget.selectedRoom,
                guest: guest,
                name: nameController.text,
                email: emailController.text,
                phone: phoneController.text,
                paymentMethod: paymentMethod,
                checkInDate: checkInDate!,
                checkOutDate: checkOutDate!,
                bookingData: data['data'],
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          checkInDate = picked;

          if (checkOutDate != null && checkOutDate!.isBefore(picked)) {
            checkOutDate = null;
          }
        } else {
          if (checkInDate != null && !picked.isAfter(checkInDate!)) {
            showDialog(
              context: context,

              builder: (context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),

                  title: const Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.orange),

                      SizedBox(width: 8),

                      Text("Tanggal Tidak Valid"),
                    ],
                  ),

                  content: const Text(
                    "Check-out harus setelah tanggal check-in.",
                  ),

                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      child: const Text(
                        "OK",
                        style: TextStyle(
                          color: Color(0xFF5F6F52),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );

            return;
          }

          checkOutDate = picked;
        }

        dateError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;

    final String hotelPrice = hotel["price"] ?? "Rp0";

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        centerTitle: true,

        title: const Text(
          "Reservation",

          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),

        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Form(
        key: _formKey,

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              /// HOTEL INFO
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,

                  borderRadius: BorderRadius.circular(24),
                ),

                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),

                      child: buildNetworkImage(
                        hotel["image"] ?? "",
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        fallbackHotelId: hotel["id"],
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            hotel["title"] ?? "Hotel",

                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            widget.selectedRoom,

                            style: TextStyle(color: Colors.grey.shade700),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            hotelPrice,

                            style: const TextStyle(
                              color: Color(0xFF5F6F52),

                              fontWeight: FontWeight.bold,

                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              /// DATA PEMESAN
              const Text(
                "Data Pemesan",

                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 18),

              customField(
                controller: nameController,

                hint: "Nama Lengkap",

                icon: Icons.person_rounded,
                readOnly: true,
              ),

              const SizedBox(height: 16),

              customField(
                controller: emailController,

                hint: "Email",

                icon: Icons.email_rounded,

                readOnly: true,
              ),

              const SizedBox(height: 16),

              customField(
                controller: phoneController,

                hint: "Nomor Telepon",

                icon: Icons.phone_rounded,

                readOnly: true,
              ),

              const SizedBox(height: 32),

              /// TANGGAL
              const Text(
                "Tanggal Reservasi",

                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: dateCard(
                      title: "Check-in",

                      value: checkInDate == null
                          ? "Pilih tanggal"
                          : "${checkInDate!.day}/${checkInDate!.month}/${checkInDate!.year}",

                      onTap: () {
                        selectDate(context, true);
                      },

                      isError: dateError,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: dateCard(
                      title: "Check-out",

                      value: checkOutDate == null
                          ? "Pilih tanggal"
                          : "${checkOutDate!.day}/${checkOutDate!.month}/${checkOutDate!.year}",

                      onTap: () {
                        selectDate(context, false);
                      },

                      isError: dateError,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              /// GUEST
              const Text(
                "Jumlah Tamu",

                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "Guest",

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Maksimal $maxGuests tamu",

                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (guest > 1) {
                              setState(() {
                                guest--;
                              });
                            }
                          },

                          child: circleButton(Icons.remove),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),

                          child: Text(
                            guest.toString(),

                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            if (guest < maxGuests) {
                              setState(() {
                                guest++;
                              });
                            }
                          },

                          child: circleButton(
                            Icons.add,
                            isDisabled: guest >= maxGuests,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              /// PAYMENT
              const Text(
                "Metode Pembayaran",

                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 18),

              paymentItem("QRIS", Icons.qr_code_rounded),

              paymentItem("Bank Transfer", Icons.account_balance_rounded),

              paymentItem("GoPay", Icons.account_balance_wallet_rounded),

              const SizedBox(height: 32),

              /// SUMMARY
              const Text(
                "Ringkasan Pembayaran",

                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 18),

              summaryItem(
                "Harga Kamar",
                formatCurrency(roomPrice),
              ),

              const Divider(height: 34),

              summaryItem(
                "Total",
                formatCurrency(roomPrice),
                isTotal: true,
              ),

              const SizedBox(height: 40),

              /// BUTTON
              if (submitError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE94235).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE94235)),
                  ),
                  child: Text(
                    submitError!,
                    style: const TextStyle(
                      color: Color(0xFFE94235),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          final isValid = _formKey.currentState!.validate();

                          setState(() {
                            submitError = null;
                            dateError =
                                checkInDate == null || checkOutDate == null;
                          });

                          if (!isValid || dateError) {
                            if (dateError) {
                              showDialog(
                                context: context,

                                builder: (context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),

                                    title: const Row(
                                      children: [
                                        Icon(
                                          Icons.warning_rounded,
                                          color: Colors.orange,
                                        ),

                                        SizedBox(width: 8),

                                        Text("Tanggal Belum Dipilih"),
                                      ],
                                    ),

                                    content: const Text(
                                      "Silakan pilih tanggal check-in dan check-out.",
                                    ),

                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },

                                        child: const Text(
                                          "OK",
                                          style: TextStyle(
                                            color: Color(0xFF5F6F52),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }

                            return;
                          }

                          createBooking();
                        },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F6F52),

                    padding: const EdgeInsets.symmetric(vertical: 18),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Buat Pemesanan",

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget customField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? fieldType,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly : readOnly,

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "$hint wajib diisi";
        }

        /// NAME VALIDATION
        if (fieldType == "name") {
          final nameRegex = RegExp(r"^[a-zA-Z\s.\'’-]+$");

          if (!nameRegex.hasMatch(value)) {
            return "Nama hanya boleh huruf";
          }

          if (value.trim().length < 3) {
            return "Nama minimal 3 karakter";
          }

          if (value.trim().length > 50) {
            return "Nama terlalu panjang";
          }
        }

        /// EMAIL VALIDATION
        if (fieldType == "email") {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

          if (!emailRegex.hasMatch(value)) {
            return "Format email tidak valid";
          }
        }

        /// PHONE VALIDATION
        if (fieldType == "phone") {
          final phoneRegex = RegExp(r'^[0-9]+$');

          if (!phoneRegex.hasMatch(value)) {
            return "Nomor telepon hanya boleh angka";
          }

          if (value.length < 10 || value.length > 13) {
            return "Nomor telepon harus 10-13 digit";
          }
        }

        /// IDENTITY VALIDATION
        if (fieldType == "identity") {
          /// kalau semua angka = NIK
          final nikRegex = RegExp(r'^[0-9]+$');

          /// huruf + angka untuk passport
          final passportRegex = RegExp(r'^[a-zA-Z0-9]+$');

          /// NIK
          if (nikRegex.hasMatch(value)) {
            if (value.length != 16) {
              return "NIK harus 16 digit";
            }
          }
          /// PASSPORT
          else {
            if (!passportRegex.hasMatch(value)) {
              return "Passport hanya boleh huruf & angka";
            }

            if (value.length < 6) {
              return "Passport minimal 6 karakter";
            }
          }
        }

        return null;
      },

      decoration: InputDecoration(
        hintText: hint,

        prefixIcon: Icon(icon, color: const Color(0xFF5F6F52)),

        filled: true,

        fillColor: Colors.grey.shade100,

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),

          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),

          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),

          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),

          borderSide: const BorderSide(color: Color(0xFF5F6F52), width: 1.5),
        ),
      ),
    );
  }

  Widget dateCard({
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool isError,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.grey.shade100,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: isError ? Colors.red : Colors.transparent,

            width: 1.5,
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(title, style: TextStyle(color: Colors.grey.shade700)),

            const SizedBox(height: 8),

            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget circleButton(IconData icon, {bool isDisabled = false}) {
    return Container(
      padding: const EdgeInsets.all(6),

      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade400 : const Color(0xFF5F6F52),
        shape: BoxShape.circle,
      ),

      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget paymentItem(String title, IconData icon) {
    final bool isSelected = paymentMethod == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          paymentMethod = title;
        });
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 14),

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEFAE0) : Colors.white,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: isSelected ? const Color(0xFF5F6F52) : Colors.grey.shade300,
          ),
        ),

        child: Row(
          children: [
            Icon(
              icon,

              color: isSelected ? const Color(0xFF5F6F52) : Colors.grey,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,

                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),

            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF5F6F52)),
          ],
        ),
      ),
    );
  }

  Widget summaryItem(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            title,

            style: TextStyle(
              fontSize: isTotal ? 18 : 15,

              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),

          Text(
            value,

            style: TextStyle(
              fontSize: isTotal ? 18 : 15,

              fontWeight: FontWeight.bold,

              color: isTotal ? const Color(0xFF5F6F52) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
