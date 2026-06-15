import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:restify/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_utils.dart';

class BookingDetailPage extends StatelessWidget {
  final Map<String, dynamic> hotel;

  final String selectedRoom;
  final String name;
  final String email;
  final String phone;
  final String paymentMethod;
  final String status;
  final String bookingCode;
  final int bookingId;

  final DateTime checkInDate;
  final DateTime checkOutDate;

  final int guest;

  const BookingDetailPage({
    super.key,

    required this.hotel,
    required this.selectedRoom,
    required this.name,
    required this.email,
    required this.phone,
    required this.paymentMethod,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guest,
    required this.status,
    required this.bookingCode,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    final int roomPrice =
        int.tryParse(
          hotel["price"]
              .toString()
              .replaceAll("Rp", "")
              .replaceAll(".", "")
              .replaceAll(",", ""),
        ) ??
        0;

    String formatRupiah(int value) {
      return "Rp${value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      )}";
    }

    /// =========================
    /// STATUS STYLE
    /// =========================
    Color statusColor;
    IconData statusIcon;
    String statusText;

    final normalizedStatus = status.toLowerCase();

    if (normalizedStatus == "upcoming" ||
        normalizedStatus == "pending" ||
        normalizedStatus == "confirmed") {
      statusColor = const Color(0xFF5F6F52);

      statusIcon = Icons.access_time_filled_rounded;

      statusText = "Booking Akan Datang";
    } else if (normalizedStatus == "completed" ||
        normalizedStatus == "checked_in" ||
        normalizedStatus == "checked_out") {
      statusColor = const Color(0xFF5F6772);

      statusIcon = Icons.check_circle_rounded;

      statusText = "Booking Selesai";
    } else {
      statusColor = const Color(0xFFD85C5F);

      statusIcon = Icons.cancel_rounded;

      statusText = "Booking Dibatalkan";
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,

        centerTitle: true,

        title: const Text(
          "Detail Pemesanan",

          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),

        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// =========================
            /// STATUS BOOKING
            /// =========================
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),

                borderRadius: BorderRadius.circular(24),

                border: Border.all(color: statusColor, width: 1.2),
              ),

              child: Column(
                children: [
                  Icon(statusIcon, color: statusColor, size: 70),

                  const SizedBox(height: 14),

                  Text(
                    statusText,

                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Booking Code : $bookingCode",

                    style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            /// =========================
            /// HOTEL INFO
            /// =========================
            sectionTitle("Informasi Hotel"),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(18),

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

                        const SizedBox(height: 8),

                        Text(
                          selectedRoom,

                          style: TextStyle(color: Colors.grey.shade700),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          formatRupiah(roomPrice),

                          style: const TextStyle(
                            color: Color(0xFF5F6F52),

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            /// =========================
            /// DETAIL RESERVASI
            /// =========================
            sectionTitle("Detail Reservasi"),

            const SizedBox(height: 16),

            detailCard(
              children: [
                detailItem(
                  "Check-in",

                  "${checkInDate.day}/${checkInDate.month}/${checkInDate.year}",
                ),

                detailItem(
                  "Check-out",

                  "${checkOutDate.day}/${checkOutDate.month}/${checkOutDate.year}",
                ),

                detailItem("Jumlah Tamu", "$guest Tamu"),

                detailItem("Metode Pembayaran", paymentMethod),
              ],
            ),

            const SizedBox(height: 28),

            /// =========================
            /// DATA PEMESAN
            /// =========================
            sectionTitle("Data Pemesan"),

            const SizedBox(height: 16),

            detailCard(
              children: [
                detailItem("Nama", name),

                detailItem("Email", email),

                detailItem("Nomor Telepon", phone),
              ],
            ),

            const SizedBox(height: 28),

            /// =========================
            /// PEMBAYARAN
            /// =========================
            sectionTitle("Ringkasan Pembayaran"),

            const SizedBox(height: 16),

            detailCard(
              children: [
                detailItem(
                  "Harga Kamar",
                  formatRupiah(roomPrice),
                ),

                const Divider(height: 30),

                detailItem(
                  "Total",
                  formatRupiah(roomPrice),
                  isTotal: true,
                ),
              ],
            ),

            const SizedBox(height: 34),

            /// =========================
            /// BUTTON
            /// =========================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Batalkan Booking"),
                      content: const Text(
                        "Apakah kamu yakin ingin membatalkan pemesanan ini?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Tidak"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Ya"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await cancelBooking(context);
                  }
                },

                icon: const Icon(Icons.cancel_rounded, color: Colors.white),

                label: const Text(
                  "Batalkan Pemesanan",

                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 232, 2, 2),

                  padding: const EdgeInsets.symmetric(vertical: 18),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> cancelBooking(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse(

          //punya Nada
          'https://pelt-womanlike-popular.ngrok-free.dev/api/user/cancel-booking/$bookingId',
          
          // punya Adam
          //'https://underwear-yeast-aching.ngrok-free.dev/api/user/cancel-booking/$bookingId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const HomePage(
                initialIndex: 2,
              ),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal membatalkan booking"),
          ),
        );
      }
    }
  }

  Widget sectionTitle(String title) {
    return Text(
      title,

      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget detailCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,

        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(children: children),
    );
  }

  Widget detailItem(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style: TextStyle(
              fontSize: isTotal ? 17 : 15,

              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              value,

              textAlign: TextAlign.end,

              style: TextStyle(
                fontSize: isTotal ? 17 : 15,

                fontWeight: FontWeight.bold,

                color: isTotal ? const Color(0xFF5F6F52) : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
