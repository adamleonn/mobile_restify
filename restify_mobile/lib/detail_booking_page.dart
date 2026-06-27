import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:restify/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_utils.dart';
import 'pdf_service.dart';
import 'config.dart';
import 'currency_utils.dart';

class BookingDetailPage extends StatefulWidget {
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
  final Map<String, dynamic>? rating;

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
    this.rating,
  });

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  Map<String, dynamic>? rating;
  String currentStatus = "";

  @override
  void initState() {
    super.initState();
    rating = widget.rating;
    currentStatus = widget.status;
    fetchBookingDetail();
  }

  Future<void> fetchBookingDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/booking/${widget.bookingId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final bookingData = decoded['data'];
        if (bookingData != null) {
          if (mounted) {
            setState(() {
              rating = bookingData['rating'];
              currentStatus = bookingData['status'] ?? widget.status;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching booking detail: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final selectedRoom = widget.selectedRoom;
    final name = widget.name;
    final email = widget.email;
    final phone = widget.phone;
    final paymentMethod = widget.paymentMethod;
    final bookingCode = widget.bookingCode;
    final checkInDate = widget.checkInDate;
    final checkOutDate = widget.checkOutDate;
    final guest = widget.guest;
    final status = currentStatus;

    final int roomPrice =
        int.tryParse(
          hotel["price"]
              .toString()
              .replaceAll("Rp", "")
              .replaceAll(".", "")
              .replaceAll(",", ""),
        ) ??
        0;


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
            /// DOWNLOAD PDF RECEIPT
            /// =========================
            if (normalizedStatus != "cancelled" &&
                normalizedStatus != "completed" &&
                normalizedStatus != "checked_out") ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    PdfService.generateAndPrintReceipt(
                      hotel: hotel,
                      selectedRoom: selectedRoom,
                      name: name,
                      email: email,
                      phone: phone,
                      paymentMethod: paymentMethod,
                      checkInDate: checkInDate,
                      checkOutDate: checkOutDate,
                      guest: guest,
                      bookingCode: bookingCode,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                  label: const Text(
                    "Unduh Bukti Pembayaran (PDF)",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB99470), // elegant brown
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            /// =========================
            /// BUTTON
            /// =========================
            if (normalizedStatus == "upcoming" ||
                normalizedStatus == "pending" ||
                normalizedStatus == "confirmed")
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
                      if (!context.mounted) return; await cancelBooking(context);
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
              )
            else if (normalizedStatus == "checked_in")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Checkout"),
                        content: const Text(
                          "Apakah kamu yakin ingin checkout dari pesanan ini?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Batal"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Ya, Checkout"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (!context.mounted) return; await checkoutBooking(context);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: const Text(
                    "Checkout",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F6F52),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              )
            else if (normalizedStatus == "completed")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showRatingModal(context);
                  },
                  icon: Icon(
                    rating != null ? Icons.edit_rounded : Icons.star_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    rating != null ? "Edit Ulasan" : "Beri Ulasan",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB99470),
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
          '${Config.baseUrl}/api/user/cancel-booking/${widget.bookingId}',
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
                initialIndex: 1,
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

  Future<void> checkoutBooking(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse(
          '${Config.baseUrl}/api/user/checkout/${widget.bookingId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Berhasil checkout. Silakan tinggalkan ulasan!"),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const HomePage(
                initialIndex: 1, // Go to bookings
              ),
            ),
            (route) => false,
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gagal checkout"),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menghubungi server"),
          ),
        );
      }
    }
  }

  void showRatingModal(BuildContext context) {
    int ratingValue = rating != null ? (int.tryParse(rating!['rating'].toString()) ?? 5) : 5;
    TextEditingController reviewController = TextEditingController(
      text: rating != null ? (rating!['review'] ?? '').toString() : '',
    );
    File? reviewImage;
    String? existingImageUrl = rating != null && rating!['image'] != null ? rating!['image'].toString() : null;

    Future<void> pickReviewImage(StateSetter modalSetState) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        modalSetState(() {
          reviewImage = File(pickedFile.path);
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating != null ? "Edit ulasan menginapmu" : "Bagaimana pengalaman menginapmu?",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < ratingValue
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 40,
                          ),
                          onPressed: () {
                            setState(() {
                              ratingValue = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Ceritakan pengalamanmu (opsional)...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (reviewImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              reviewImage!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  reviewImage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (existingImageUrl != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              existingImageUrl!.startsWith('http')
                                  ? existingImageUrl!
                                  : '${Config.baseUrl}/storage/${existingImageUrl!}',
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  existingImageUrl = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => pickReviewImage(setState),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5F6F52),
                            side: const BorderSide(color: Color(0xFF5F6F52)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.add_a_photo_rounded),
                          label: const Text("Tambah Foto Ulasan (Opsional)"),
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final bool removeImage = (existingImageUrl == null && reviewImage == null && rating != null && rating!['image'] != null);
                          await submitRating(
                            context,
                            ratingValue,
                            reviewController.text,
                            reviewImage,
                            removeImage,
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F6F52),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Kirim Ulasan",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> submitRating(BuildContext context, int ratingValue, String review, File? image, bool removeImage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.baseUrl}/api/user/ratings'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      request.fields['booking_id'] = widget.bookingId.toString();
      request.fields['rating'] = ratingValue.toString();
      request.fields['review'] = review;
      if (removeImage) {
        request.fields['remove_image'] = 'true';
      }

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
          ),
        );
      }

      final response = await request.send();

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Terima kasih atas ulasannya!"),
            ),
          );
        }
        fetchBookingDetail();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gagal mengirim ulasan atau ulasan sudah ada"),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menghubungi server"),
          ),
        );
      }
    }
  }
}
