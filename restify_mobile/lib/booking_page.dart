import 'package:flutter/material.dart';
import 'detail_booking_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  List<dynamic> bookings = [];

  bool isLoading = true;

  String selectedTab = "Upcoming";
  String userName = "-";
  String userEmail = "-";
  String userPhone = "-";

  Future<void> getBookingHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');
      userName = prefs.getString('name') ?? "-";
      userEmail = prefs.getString('email') ?? "-";
      userPhone = prefs.getString('phone') ?? "-";

      final response = await http.get(
        Uri.parse(
          'https://underwear-yeast-aching.ngrok-free.dev/api/user/booking-history',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          bookings = data['data'];

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getBookingHistory();
  }

  DateTime parseBookingDate(dynamic value) {
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  String formatBookingDate(dynamic value) {
    final date = parseBookingDate(value);
    return "${date.day}/${date.month}/${date.year}";
  }

  String formatRupiah(dynamic value) {
    final price = double.tryParse(value.toString()) ?? 0;
    final parts = price.toStringAsFixed(0).split('');
    final result = StringBuffer();

    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(parts[i]);
    }

    return "Rp ${result.toString()}";
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = bookings.where((booking) {
      final status = booking['status'];

      if (selectedTab == 'Upcoming') {
        return status == 'pending' || status == 'confirmed';
      }

      if (selectedTab == 'Completed') {
        return status == 'checked_in' || status == 'completed';
      }

      if (selectedTab == 'Cancelled') {
        return status == 'cancelled';
      }

      return false;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),

      body: Column(
        children: [
          /// =========================
          /// HEADER
          /// =========================
          Container(
            width: double.infinity,

            color: const Color(0xFF5F6F52),

            child: SafeArea(
              bottom: false,

              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),

                    child: Row(
                      children: [
                        Container(
                          color: Colors.transparent,

                          child: Image.asset(
                            'assets/logo/landing_page_restify.png',

                            width: 82,

                            fit: BoxFit.contain,

                            filterQuality: FilterQuality.high,
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              "Pemesanan",

                              style: TextStyle(
                                color: Colors.white,

                                fontSize: 26,

                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              "Kelola reservasi hotel kamu",

                              style: TextStyle(
                                color: Colors.white70,

                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// =========================
                  /// SEGMENTED TAB
                  /// =========================
                  Row(
                    children: [
                      buildTab(
                        title: "Upcoming",

                        activeColor: const Color(0xFF3E4B35),

                        isLeft: true,
                      ),

                      buildTab(
                        title: "Completed",

                        activeColor: const Color(0xFF5F6772),
                      ),

                      buildTab(
                        title: "Cancelled",

                        activeColor: const Color(0xFFD85C5F),

                        isRight: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// =========================
          /// BOOKING LIST
          /// =========================
          Expanded(
            child: filteredBookings.isEmpty
                ? Center(
                    child: Text(
                      "Belum ada booking",

                      style: TextStyle(
                        color: Colors.grey.shade600,

                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),

                    itemCount: filteredBookings.length,

                    separatorBuilder: (_, _) => const SizedBox(height: 14),

                    itemBuilder: (context, index) {
                      final booking =
                          filteredBookings[index] as Map<String, dynamic>;

                      return bookingCard(booking: booking);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// TAB
  /// =========================
  Widget buildTab({
    required String title,
    required Color activeColor,
    bool isLeft = false,
    bool isRight = false,
  }) {
    final isSelected = selectedTab == title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = title;
          });
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),

          padding: const EdgeInsets.symmetric(vertical: 15),

          decoration: BoxDecoration(
            color: isSelected ? activeColor : activeColor.withValues(alpha: 0.15),

            borderRadius: BorderRadius.only(
              topLeft: isLeft ? const Radius.circular(18) : Radius.zero,

              topRight: isRight ? const Radius.circular(18) : Radius.zero,
            ),

            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,

                width: 3,
              ),
            ),
          ),

          child: Center(
            child: Text(
              title,

              style: TextStyle(
                fontSize: 13.5,

                fontWeight: FontWeight.w700,

                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// =========================
  /// BOOKING CARD
  /// =========================
  Widget bookingCard({required Map<String, dynamic> booking}) {
    final room = booking['room'] as Map<String, dynamic>?;
    final hotelData = room?['hotel'] as Map<String, dynamic>?;
    final payment = booking['payment'] as Map<String, dynamic>?;

    final hotel = (hotelData?['name'] ?? '-').toString();
    final location = (hotelData?['city'] ?? '-').toString();
    final selectedRoom = (room?['room_type'] ?? '-').toString();
    final status = (booking['status'] ?? '-').toString();
    final checkIn = formatBookingDate(booking['check_in_date']);
    final checkOut = formatBookingDate(booking['check_out_date']);
    final date = '$checkIn - $checkOut';
    final rawBookingImg = (hotelData?['image_url'] ?? '').toString();
    final image = rawBookingImg.startsWith('/')
        ? 'https://underwear-yeast-aching.ngrok-free.dev$rawBookingImg'
        : rawBookingImg
            .replaceAll("http://localhost:8000", "https://underwear-yeast-aching.ngrok-free.dev")
            .replaceAll("http://127.0.0.1:8000", "https://underwear-yeast-aching.ngrok-free.dev");
    final price = formatRupiah(booking['total_price']);

    Color statusColor;

    if (status == 'pending' || status == 'confirmed') {
      statusColor = const Color(0xFF5F6F52);
    } else if (status == 'completed' || status == 'checked_in') {
      statusColor = const Color(0xFF5F6772);
    } else {
      statusColor = const Color(0xFFD85C5F);
    }

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 10,

            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          /// STATUS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),

              borderRadius: BorderRadius.circular(20),
            ),

            child: Text(
              status,

              style: TextStyle(
                color: statusColor,

                fontSize: 12,

                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 14),

          /// HOTEL
          Text(
            hotel,

            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          /// LOCATION
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,

                size: 17,

                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  location,

                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// DATE
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,

                size: 17,

                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  date,

                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          /// BUTTON
          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingDetailPage(
                      hotel: {
                        "id": hotelData?["id"],
                        "title": hotel,
                        "image": image,
                        "price": price,
                      },

                      selectedRoom: selectedRoom,

                      name: userName,

                      email: userEmail,

                      phone: userPhone,

                      paymentMethod:
                          (booking['payment_method'] ??
                                  payment?['payment_method'] ??
                                  '-')
                              .toString(),

                      checkInDate:
                          parseBookingDate(booking['check_in_date']),

                      checkOutDate:
                          parseBookingDate(booking['check_out_date']),

                      guest:
                          int.tryParse(
                            (booking['guests'] ?? '1').toString(),
                          ) ??
                          1,

                      status: status,

                      bookingCode:
                          (payment?['transaction_code'] ?? '-')
                              .toString(),

                      bookingId: booking['id'],
                    ),
                  ),
                );

                debugPrint("RESULT DARI DETAIL = $result");

                if (result == true) {
                  await getBookingHistory();

                  setState(() {
                    selectedTab = "Cancelled";
                  });
                }
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F6F52),

                elevation: 0,

                padding: const EdgeInsets.symmetric(vertical: 15),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              child: const Text(
                "Lihat Detail",

                style: TextStyle(
                  color: Colors.white,

                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
