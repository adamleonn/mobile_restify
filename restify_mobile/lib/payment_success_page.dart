import 'package:flutter/material.dart';
import 'detail_booking_page.dart';
import 'home_page.dart';

class PaymentSuccessPage extends StatelessWidget {
  final Map<String, dynamic> hotel;
  final String selectedRoom;
  final int guest;
  final String name;
  final String email;
  final String phone;
  final String paymentMethod;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final Map<String, dynamic> bookingData;

  const PaymentSuccessPage({
    super.key,
    required this.hotel,
    required this.selectedRoom,
    required this.guest,
    required this.name,
    required this.email,
    required this.phone,
    required this.paymentMethod,
    required this.checkInDate,
    required this.checkOutDate,
    required this.bookingData,
  });

  @override
  Widget build(BuildContext context) {
    print("BOOKING DATA:");
print(bookingData);
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              /// SUCCESS ICON
              Container(
                width: 130,
                height: 130,

                decoration: BoxDecoration(
                  color: const Color(0xFF5F6F52).withOpacity(0.1),

                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.check_circle_rounded,

                  color: Color(0xFF5F6F52),

                  size: 90,
                ),
              ),

              const SizedBox(height: 36),

              /// TITLE
              const Text(
                "Pemesanan Berhasil",

                textAlign: TextAlign.center,

                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              Text(
                "Reservasi hotel kamu berhasil dilakukan.",

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              /// BOOKING CARD
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,

                  borderRadius: BorderRadius.circular(24),
                ),

                child: Column(
                  children: [
                    infoItem("Hotel", hotel["title"] ?? "-"),

                    const SizedBox(height: 18),

                    infoItem("Room", selectedRoom),

                    const SizedBox(height: 18),

                    infoItem(
                      "Status",
                      bookingData["payment_status"] ?? "pending",
                    ),

                    const SizedBox(height: 18),

                    infoItem(
                      "Kode Pemesanan",
                      bookingData["payment"]?["transaction_code"] ?? "-",
                    ),
                  ],
                ),
              ),

              const Spacer(),

              /// DETAIL BOOKING BUTTON
              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (_) => BookingDetailPage(
                          hotel: hotel,

                          selectedRoom: selectedRoom,

                          name: name,

                          email: email,

                          phone: phone,

                          paymentMethod: paymentMethod,

                          checkInDate: checkInDate,

                          checkOutDate: checkOutDate,

                          guest: guest,

                          status: 'Upcoming',

                          bookingCode:
                              bookingData["payment"]?["transaction_code"] ?? "-",

                          bookingId: bookingData["id"] ?? bookingData["booking_id"] ?? 0,
                        ),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F6F52),

                    padding: const EdgeInsets.symmetric(vertical: 18),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: const Text(
                    "Lihat Detail Booking",

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /// VIEW BOOKING
              SizedBox(
                width: double.infinity,

                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,

                      MaterialPageRoute(
                        builder: (_) => const HomePage(initialIndex: 2),
                      ),

                      (route) => false,
                    );
                  },

                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),

                    side: const BorderSide(color: Color(0xFF5F6F52)),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: const Text(
                    "Lihat Semua Booking",

                    style: TextStyle(
                      color: Color(0xFF5F6F52),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /// BACK HOME
              SizedBox(
                width: double.infinity,

                child: TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,

                      MaterialPageRoute(builder: (_) => const HomePage()),

                      (route) => false,
                    );
                  },

                  child: Text(
                    "Kembali ke Home",

                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoItem(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Text(
          title,

          style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
        ),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,

            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
