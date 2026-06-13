import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:restify/list_hotel_page.dart';
import 'profile_page.dart';
import 'booking_page.dart';
import 'detail_hotel_page.dart';
import 'favorite_page.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Set<String> favoriteHotels = {};
Map<String, Map<String, dynamic>> favoriteHotelDetails = {};
ValueNotifier<int> favoriteVersion = ValueNotifier<int>(0);

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int currentIndex;
  final GlobalKey<_HomeContentState> homeKey = GlobalKey<_HomeContentState>();
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pages = [
      HomeContent(key: homeKey),

      const Center(
        child: Text("AI Assistant Page", style: TextStyle(fontSize: 22)),
      ),

      const BookingPage(),

      const FavoritePage(),

      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },

        child: IndexedStack(index: currentIndex, children: pages),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
          if (index == 0) {
            homeKey.currentState?.loadUserData();
          }
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color(0xFF5F6F52),
        unselectedItemColor: Colors.grey,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),

          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded),
            label: "Smart Travel",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: "Pemesanan",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: "Favorit",
          ),

          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<Map<String, dynamic>> hotels = [];
  bool isLoading = true;
  String userName = "Guest";

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString('name') ?? "Guest";
    setState(() {
      userName = fullName.trim().split(' ').first;
    });
  }

  bool isCityInDevelopment(String city) {
    return city != "Bandung" && city != "Jakarta";
  }

  Future<void> fetchHotels({String? city}) async {
    final cityName = city ?? selectedCity;

    if (isCityInDevelopment(cityName)) {
      setState(() {
        hotels = [];
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final uri = Uri.parse(
        'https://pelt-womanlike-popular.ngrok-free.dev/api/hotels',
      ).replace(queryParameters: {'city': cityName, 'per_page': '50'});

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (!mounted || selectedCity != cityName) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List rawHotels = data['data'] ?? [];

        setState(() {
          hotels = rawHotels.map<Map<String, dynamic>>((h) {
            return {
              "id": h["id"],
              "city": (h["city"] ?? h["location"] ?? "").toString(),
              "name": (h["name"] ?? h["title"] ?? "").toString(),
              "address": (h["address"] ?? "").toString(),
              "image_url":
                  h["image_url"] ??
                  "https://via.placeholder.com/400x300.png?text=No+Image",
              "average_rating":
                  double.tryParse(
                    (h["average_rating"] ?? h["rating"] ?? "4.5").toString(),
                  ) ??
                  4.5,
              "lowest_price":
                  double.tryParse(
                    (h["lowest_price"] ?? h["price"] ?? "0").toString(),
                  ) ??
                  0,
            };
          }).toList();

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted || selectedCity != cityName) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
    fetchHotels();
  }

  bool get isSearchActive => searchQuery.trim().isNotEmpty;

  String selectedCity = "Bandung";

  final List<String> cities = ["Bali", "Bandung", "Jakarta", "Yogyakarta"];

  bool isDropdownOpen = false;
  bool hasNewNotification = true;

  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";

  final CarouselSliderController carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredHotels = hotels.where((hotel) {
      final matchesCity =
          hotel["city"].toString().toLowerCase() == selectedCity.toLowerCase();

      final matchesSearch = hotel["name"].toString().toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      return matchesCity && matchesSearch;
    }).toList();

    filteredHotels.sort(
      (a, b) => a["name"].toString().compareTo(b["name"].toString()),
    );

    final bool isDevelopmentCity = isCityInDevelopment(selectedCity);

    final sortedHotels = [...hotels]
      ..sort((a, b) => a["name"].toString().compareTo(b["name"].toString()));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              /// =========================
              /// HEADER
              /// =========================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/logo/landing_page_restify.png',
                          width: 45,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            "Halo, $userName 👋",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      /// NOTIFICATION
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                hasNewNotification = false;
                              });

                              showModalBottomSheet(
                                context: context,

                                backgroundColor: Colors.white,

                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                ),

                                builder: (context) {
                                  return Padding(
                                    padding: const EdgeInsets.all(24),

                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        /// HANDLE
                                        Center(
                                          child: Container(
                                            width: 50,

                                            height: 5,

                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade300,

                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        const Text(
                                          "Notifikasi",

                                          style: TextStyle(
                                            fontSize: 22,

                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 20),

                                        notificationItem(
                                          title: "Booking Berhasil 🎉",

                                          subtitle:
                                              "Reservasi Padma Hotel Bandung berhasil.",

                                          icon: Icons.check_circle_rounded,
                                        ),

                                        notificationItem(
                                          title: "Check-in Besok",

                                          subtitle:
                                              "Jangan lupa check-in pada 12 Mei 2026.",

                                          icon: Icons.hotel_rounded,
                                        ),

                                        notificationItem(
                                          title: "Promo Baru ✨",

                                          subtitle:
                                              "Diskon hingga 40% untuk hotel pilihan.",

                                          icon: Icons.local_offer_rounded,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },

                            child: Container(
                              padding: const EdgeInsets.all(10),

                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,

                                shape: BoxShape.circle,
                              ),

                              child: const Icon(
                                Icons.notifications_none_rounded,

                                color: Color(0xFF5F6F52),

                                size: 24,
                              ),
                            ),
                          ),

                          /// RED DOT
                          if (hasNewNotification)
                            Positioned(
                              right: 6,
                              top: 6,

                              child: Container(
                                width: 8,
                                height: 8,

                                decoration: const BoxDecoration(
                                  color: Colors.red,

                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      /// DROPDOWN
                      SizedBox(
                        width: 150,
                        height: 42,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEFAE0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              value: selectedCity,

                              isDense: true,

                              style: const TextStyle(
                                color: Colors.black,

                                fontSize: 14,

                                fontWeight: FontWeight.w500,
                              ),

                              onMenuStateChange: (isOpen) {
                                setState(() {
                                  isDropdownOpen = isOpen;
                                });
                              },

                              iconStyleData: IconStyleData(
                                icon: AnimatedRotation(
                                  turns: isDropdownOpen ? 0.5 : 0,

                                  duration: const Duration(milliseconds: 250),

                                  child: const Icon(
                                    Icons.keyboard_arrow_down_rounded,

                                    color: Color(0xFF5F6F52),
                                  ),
                                ),
                              ),

                              buttonStyleData: const ButtonStyleData(
                                padding: EdgeInsets.zero,

                                height: 40,
                              ),

                              dropdownStyleData: DropdownStyleData(
                                width: 150,

                                maxHeight: 200,

                                offset: const Offset(-12, -4),

                                decoration: BoxDecoration(
                                  color: Colors.white,

                                  borderRadius: BorderRadius.circular(16),
                                ),

                                elevation: 3,
                              ),

                              menuItemStyleData: const MenuItemStyleData(
                                height: 45,
                              ),

                              items: cities.map((city) {
                                final bool isSelected = city == selectedCity;

                                return DropdownMenuItem<String>(
                                  value: city,

                                  child: SizedBox(
                                    width: double.infinity,

                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,

                                        vertical: 6,
                                      ),

                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFFEFAE0)
                                            : Colors.transparent,

                                        borderRadius: BorderRadius.circular(10),
                                      ),

                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,

                                            size: 16,

                                            color: isSelected
                                                ? const Color(0xFF5F6F52)
                                                : Colors.grey,
                                          ),

                                          const SizedBox(width: 4),

                                          Text(
                                            city,

                                            style: TextStyle(
                                              fontSize: 13,

                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,

                                              color: isSelected
                                                  ? const Color(0xFF5F6F52)
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),

                              selectedItemBuilder: (context) {
                                return cities.map((city) {
                                  return Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,

                                        size: 16,

                                        color: Color(0xFF5F6F52),
                                      ),

                                      const SizedBox(width: 4),

                                      Text(
                                        city,

                                        style: const TextStyle(
                                          fontSize: 13,

                                          color: Colors.black,

                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList();
                              },

                              onChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  selectedCity = value;
                                });

                                fetchHotels(city: value);

                                if (isCityInDevelopment(value)) {
                                  Flushbar(
                                    flushbarPosition: FlushbarPosition.BOTTOM,

                                    margin: const EdgeInsets.all(20),

                                    borderRadius: BorderRadius.circular(20),

                                    backgroundColor: const Color(0xFF5F6F52),

                                    duration: const Duration(seconds: 2),

                                    animationDuration: const Duration(
                                      milliseconds: 900,
                                    ),

                                    boxShadows: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),

                                        blurRadius: 18,

                                        offset: const Offset(0, 6),
                                      ),
                                    ],

                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),

                                    messageText: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),

                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.15,
                                            ),

                                            shape: BoxShape.circle,
                                          ),

                                          child: const Icon(
                                            Icons.construction_rounded,

                                            color: Colors.white,

                                            size: 20,
                                          ),
                                        ),

                                        const SizedBox(width: 14),

                                        Expanded(
                                          child: Text(
                                            "$value masih dalam tahap pengembangan 🚧",

                                            style: const TextStyle(
                                              color: Colors.white,

                                              fontSize: 14,

                                              fontWeight: FontWeight.w600,

                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).show(context);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// SEARCH BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,

                  borderRadius: BorderRadius.circular(14),
                ),

                child: TextField(
                  controller: searchController,

                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },

                  decoration: const InputDecoration(
                    border: InputBorder.none,

                    icon: Icon(Icons.search),

                    hintText: "Cari hotel, villa, resort...",
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// TITLE
              if (!isSearchActive && !isDevelopmentCity) ...[
                const Text(
                  "Rekomendasi Hotel",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  "Pilihan hotel terbaik di $selectedCity",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),

                const SizedBox(height: 20),
              ],

              const SizedBox(height: 20),

              /// DEVELOPMENT BANNER
              if (isDevelopmentCity)
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFEFAE0),

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),

                        decoration: const BoxDecoration(
                          color: Color(0xFF5F6F52),

                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.construction_rounded,

                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 16),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              "Masih Tahap Pengembangan",

                              style: TextStyle(
                                fontWeight: FontWeight.bold,

                                fontSize: 15,
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              "Saat ini pemesanan hotel tersedia untuk Bandung dan Jakarta.",

                              style: TextStyle(
                                height: 1.4,

                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                /// CAROUSEL
                if (!isSearchActive) ...[
                  Stack(
                    alignment: Alignment.center,

                    children: [
                      CarouselSlider(
                        carouselController: carouselController,

                        options: CarouselOptions(
                          height: 240,

                          autoPlay: true,

                          autoPlayInterval: const Duration(seconds: 3),

                          autoPlayAnimationDuration: const Duration(
                            milliseconds: 800,
                          ),

                          enlargeCenterPage: true,

                          viewportFraction: 0.82,
                        ),

                        items: filteredHotels.take(8).map((hotel) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HotelDetailPage(hotelId: hotel['id']),
                                ),
                              );
                            },

                            child: premiumHotelCard(
                              hotel: hotel,
                              image: hotel["image_url"] ?? "",
                              title: hotel["name"] ?? "",
                              location: (hotel["city"] ?? "Unknown").toString(),
                              rating:
                                  double.tryParse(
                                    hotel["average_rating"].toString(),
                                  )?.toStringAsFixed(1) ??
                                  "4.5",

                              price: (hotel["lowest_price"] ?? 0) == 0
                                  ? "Harga belum tersedia"
                                  : formatRupiah(hotel["lowest_price"]),
                            ),
                          );
                        }).toList(),
                      ),

                      Positioned(
                        left: 10,

                        child: GestureDetector(
                          onTap: () {
                            carouselController.previousPage();
                          },

                          child: const Icon(
                            Icons.arrow_back_ios_new,

                            size: 26,

                            color: Color(0xFF5F6F52),
                          ),
                        ),
                      ),

                      Positioned(
                        right: 10,

                        child: GestureDetector(
                          onTap: () {
                            carouselController.nextPage();
                          },

                          child: const Icon(
                            Icons.arrow_forward_ios,

                            size: 26,

                            color: Color(0xFF5F6F52),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],

                /// HEADER LIST HOTEL
                if (filteredHotels.isNotEmpty || !isSearchActive) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          /// TITLE
                          Text(
                            isSearchActive
                                ? "Hasil Pencarian"
                                : "Pilihan Hotel Lainnya",

                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          /// SUBTITLE
                          const SizedBox(height: 4),

                          Text(
                            isSearchActive
                                ? "Hasil pencarian hotel di $selectedCity"
                                : "Pilihan hotel lainnya di $selectedCity",

                            style: TextStyle(
                              color: Colors.grey.shade600,

                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      /// BUTTON
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (_) => ListHotelPage(city: selectedCity),
                            ),
                          );
                        },

                        child: const Text(
                          "Lihat Semua",

                          style: TextStyle(
                            color: Color(0xFF5F6F52),

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ],

              if (!isDevelopmentCity) ...[
                const SizedBox(height: 20),

                /// JIKA ADA HOTEL
                if (filteredHotels.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    primary: false,

                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: filteredHotels.length > 3
                        ? 3
                        : filteredHotels.length,

                    separatorBuilder: (_, __) => const SizedBox(height: 16),

                    itemBuilder: (context, index) {
                      final hotel = filteredHotels[index];

                      return hotelCard(
                        hotel: hotel,
                        image: hotel["image_url"] ?? "",
                        title: hotel["name"] ?? "",
                        location: (hotel["city"] ?? "Unknown").toString(),
                        rating:
                            double.tryParse(
                              hotel["average_rating"].toString(),
                            )?.toStringAsFixed(1) ??
                            "4.5",
                        price: (hotel["lowest_price"] ?? 0) == 0
                            ? "Harga belum tersedia"
                            : formatRupiah(hotel["lowest_price"]),
                      );
                    },
                  )
                /// JIKA TIDAK ADA
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const SizedBox(height: 10),

                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,

                              size: 70,

                              color: Colors.grey.shade400,
                            ),

                            const SizedBox(height: 16),

                            const Text(
                              "Hotel / Villa / Resort\nTidak Ditemukan",

                              textAlign: TextAlign.center,

                              style: TextStyle(
                                fontSize: 20,

                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Coba gunakan kata kunci lain",

                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      /// TITLE REKOMENDASI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const Text(
                                "Rekomendasi Hotel Lainnya",

                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "Hotel populer untuk kamu",

                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),

                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (_) =>
                                      ListHotelPage(city: selectedCity),
                                ),
                              );
                            },

                            child: const Text(
                              "Lihat Semua",

                              style: TextStyle(
                                color: Color(0xFF5F6F52),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      ListView.separated(
                        shrinkWrap: true,

                        physics: const NeverScrollableScrollPhysics(),

                        itemCount: sortedHotels.length > 3
                            ? 3
                            : sortedHotels.length,

                        separatorBuilder: (_, __) => const SizedBox(height: 16),

                        itemBuilder: (context, index) {
                          final hotel = sortedHotels[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HotelDetailPage(hotelId: hotel['id']),
                                ),
                              );
                            },
                            child: hotelCard(
                              hotel: hotel,
                              image: hotel["image_url"] ?? "",
                              title: hotel["name"] ?? "",
                              location: (hotel["city"] ?? "Unknown").toString(),
                              rating:
                                  double.tryParse(
                                    hotel["average_rating"].toString(),
                                  )?.toStringAsFixed(1) ??
                                  "4.5",
                              price: (hotel["lowest_price"] ?? 0) == 0
                                  ? "Harga belum tersedia"
                                  : formatRupiah(hotel["lowest_price"]),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// =========================
  /// HOTEL CARD
  /// =========================
  Widget hotelCard({
    required Map<String, dynamic> hotel,
    required String image,
    required String title,
    required String location,
    required String price,
    required String rating,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),

            blurRadius: 10,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  height: 180,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.broken_image)),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),

              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => toggleFavorite(hotel),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      favoriteHotels.contains(title)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 18,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),

                    const SizedBox(width: 4),

                    Expanded(
                      child: Text(
                        location,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    const Icon(Icons.star, size: 16, color: Colors.amber),

                    const SizedBox(width: 4),

                    Text(rating),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  price,

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
    );
  }

  /// =========================
  /// PREMIUM HOTEL CARD
  /// =========================
  Widget premiumHotelCard({
    required Map<String, dynamic> hotel,
    required String image,
    required String title,
    required String location,
    required String rating,
    required String price,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),

            blurRadius: 12,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Stack(
        children: [
          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(22),

            child: Image.network(
              image,
              fit: BoxFit.cover,
              height: 180,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.broken_image)),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(child: CircularProgressIndicator());
              },
            ),
          ),

          /// OVERLAY
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),

              gradient: LinearGradient(
                begin: Alignment.topCenter,

                end: Alignment.bottomCenter,

                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),

          /// CONTENT
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                /// RATING
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),

                      const SizedBox(width: 4),

                      Text(
                        rating,

                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  title,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 20,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on,

                      color: Colors.white70,

                      size: 16,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      location,

                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Color(0xFF5F6F52),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFAE0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Per Malam",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5F6F52),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// FAVORITE ICON
          Positioned(
            top: 12,
            right: 12,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () => toggleFavorite(hotel),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  favoriteHotels.contains(title)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// NOTIFICATION ITEM
  /// =========================
  Widget notificationItem({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,

        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),

            decoration: const BoxDecoration(
              color: Color(0xFFFEFAE0),

              shape: BoxShape.circle,
            ),

            child: Icon(icon, color: const Color(0xFF5F6F52)),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,

                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,

                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String formatRupiah(dynamic price) {
    final value = double.tryParse(price.toString()) ?? 0;

    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  void toggleFavorite(Map<String, dynamic> hotel) {
    final hotelName = (hotel["name"] ?? "").toString();
    if (hotelName.isEmpty) return;

    setState(() {
      if (favoriteHotels.contains(hotelName)) {
        favoriteHotels.remove(hotelName);
        favoriteHotelDetails.remove(hotelName);
      } else {
        favoriteHotels.add(hotelName);
        favoriteHotelDetails[hotelName] = Map<String, dynamic>.from(hotel);
      }

      favoriteVersion.value++;
    });
  }
}
