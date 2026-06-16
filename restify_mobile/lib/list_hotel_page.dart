import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'detail_hotel_page.dart';
import 'image_utils.dart';
import 'config.dart';

const String _baseUrl = Config.baseUrl;

class ListHotelPage extends StatefulWidget {
  final String city;

  const ListHotelPage({
    super.key,
    required this.city,
  });

  @override
  State<ListHotelPage> createState() => _ListHotelPageState();
}

class _ListHotelPageState extends State<ListHotelPage> {
  List<Map<String, dynamic>> hotels = [];
  bool isLoading = true;
  bool hasError = false;
  String searchQuery = '';
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    fetchHotels();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchHotels() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final uri = Uri.parse('$_baseUrl/api/hotels').replace(queryParameters: {
        'city': widget.city,
        'per_page': '50',
      });

      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List rawList = data['data'] ?? [];

        setState(() {
          hotels = rawList.map<Map<String, dynamic>>((h) {
            return {
              'id': h['id'],
              'name': (h['name'] ?? '').toString(),
              'city': (h['city'] ?? '').toString(),
              'address': (h['address'] ?? '').toString(),
              'image_url': (h['image_url'] ?? '').toString().startsWith('/')
                  ? '$_baseUrl${h['image_url']}'
                  : (h['image_url'] ?? '').toString()
                      .replaceAll("http://localhost:8000", _baseUrl)
                      .replaceAll("http://127.0.0.1:8000", _baseUrl),
              'average_rating': double.tryParse(
                    (h['average_rating'] ?? '0').toString(),
                  ) ??
                  0.0,
              'lowest_price': double.tryParse(
                    (h['lowest_price'] ?? '0').toString(),
                  ) ??
                  0.0,
            };
          }).toList()
            ..sort((a, b) =>
                (a['name'] as String).toLowerCase().compareTo(
                    (b['name'] as String).toLowerCase()));

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  List<Map<String, dynamic>> get filteredHotels {
    if (searchQuery.trim().isEmpty) return hotels;
    final q = searchQuery.toLowerCase();
    return hotels.where((h) {
      return (h['name'] as String).toLowerCase().contains(q) ||
          (h['city'] as String).toLowerCase().contains(q) ||
          (h['address'] as String).toLowerCase().contains(q);
    }).toList();
  }

  String formatPrice(double price) {
    if (price == 0) return 'Hubungi hotel';
    final parts = price.toStringAsFixed(0).split('');
    final result = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.write('.');
      result.write(parts[i]);
    }
    return 'Rp${result.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Hotel di ${widget.city}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// SEARCH BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: searchController,
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Cari hotel, resort, villa...',
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// RESULT COUNT
            if (!isLoading && !hasError)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filteredHotels.length} hotel ditemukan',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            /// CONTENT
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5F6F52),
                      ),
                    )
                  : hasError
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off_rounded,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              const Text(
                                'Tidak dapat terhubung ke server',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: fetchHotels,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5F6F52),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : filteredHotels.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.hotel_outlined,
                                      size: 48, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  Text(
                                    searchQuery.isNotEmpty
                                        ? 'Hotel "$searchQuery" tidak ditemukan'
                                        : 'Belum ada hotel di ${widget.city}',
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              itemCount: filteredHotels.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.68,
                              ),
                              itemBuilder: (context, index) {
                                final hotel = filteredHotels[index];
                                final rating = hotel['average_rating'] as double;
                                final imageUrl = hotel['image_url'] as String;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HotelDetailPage(
                                          hotelId: hotel['id'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// IMAGE
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(22),
                                          ),
                                          child: Stack(
                                            children: [
                                              buildNetworkImage(
                                                imageUrl,
                                                height: 150,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                fallbackHotelId: hotel['id'],
                                              ),

                                              /// RATING BADGE
                                              Positioned(
                                                top: 10,
                                                right: 10,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.star,
                                                          color: Colors.amber,
                                                          size: 13),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        rating > 0
                                                            ? rating
                                                                .toStringAsFixed(
                                                                    1)
                                                            : 'Baru',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        /// CONTENT
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                /// NAME
                                                Text(
                                                  hotel['name'],
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),

                                                const SizedBox(height: 6),

                                                /// CITY
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.location_on,
                                                        size: 13,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 3),
                                                    Expanded(
                                                      child: Text(
                                                        hotel['city'],
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey.shade600,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const Spacer(),

                                                /// PRICE
                                                Text(
                                                  formatPrice(
                                                      hotel['lowest_price']
                                                          as double),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF5F6F52),
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}