import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'reservation_page.dart';
import 'image_utils.dart';
import 'map_page.dart';
import 'config.dart';

const String _detailBaseUrl = Config.baseUrl;

class HotelDetailPage extends StatefulWidget {
  final int hotelId;

  const HotelDetailPage({super.key, required this.hotelId});

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  Map<String, dynamic>? hotel;
  bool isLoading = true;
  bool hasError = false;
  int currentImage = 0;
  int? selectedRoomId;

  @override
  void initState() {
    super.initState();
    fetchHotelDetail();
  }

  Future<void> fetchHotelDetail() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('$_detailBaseUrl/api/hotels/${widget.hotelId}'),
        headers: {
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          hotel = data;
          // Auto-select first room
          final rooms = data['rooms'] as List? ?? [];
          if (rooms.isNotEmpty) {
            selectedRoomId = rooms.first['id'];
          }
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

  String formatPrice(dynamic price) {
    final val = double.tryParse(price.toString()) ?? 0;
    if (val == 0) return 'Hubungi hotel';
    final parts = val.toStringAsFixed(0).split('');
    final result = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.write('.');
      result.write(parts[i]);
    }
    return 'Rp${result.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5F6F52)),
        ),
      );
    }

    if (hasError || hotel == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat detail hotel',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchHotelDetail,
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
        ),
      );
    }

    final rawRooms = hotel!['rooms'] as List? ?? [];
    final rooms = rawRooms.map<Map<String, dynamic>>((r) {
      final item = Map<String, dynamic>.from(r);
      final rawImg = (item['image_url'] ?? '').toString();
      item['image_url'] = rawImg.startsWith('/')
          ? '$_detailBaseUrl$rawImg'
          : rawImg
              .replaceAll("http://localhost:8000", _detailBaseUrl)
              .replaceAll("http://127.0.0.1:8000", _detailBaseUrl);
      return item;
    }).toList();

    final rawHotelImg = (hotel!['image_url'] ?? '').toString();
    final imageUrl = rawHotelImg.startsWith('/')
        ? '$_detailBaseUrl$rawHotelImg'
        : rawHotelImg
            .replaceAll("http://localhost:8000", _detailBaseUrl)
            .replaceAll("http://127.0.0.1:8000", _detailBaseUrl);
    final gallery = imageUrl.isNotEmpty ? [imageUrl] : <String>[];

    // Build gallery from rooms' images too
    for (final room in rooms) {
      final roomImg = (room['image_url'] ?? '').toString();
      if (roomImg.isNotEmpty && !gallery.contains(roomImg)) {
        gallery.add(roomImg);
      }
    }

    final selectedRoom = selectedRoomId != null
        ? rooms.firstWhere(
            (r) => r['id'] == selectedRoomId,
            orElse: () => rooms.isNotEmpty ? rooms.first : {},
          )
        : (rooms.isNotEmpty ? rooms.first : <String, dynamic>{});

    final mapsLat = hotel!['latitude'];
    final mapsLng = hotel!['longitude'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ========================
                /// CAROUSEL
                /// ========================
                Stack(
                  children: [
                    gallery.isNotEmpty
                        ? CarouselSlider(
                            options: CarouselOptions(
                              height: 340,
                              viewportFraction: 1,
                              autoPlay: gallery.length > 1,
                              enlargeCenterPage: false,
                              onPageChanged: (index, _) {
                                setState(() => currentImage = index);
                              },
                            ),
                            items: gallery.map((img) {
                              return buildNetworkImage(
                                img,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                fallbackHotelId: widget.hotelId,
                              );
                            }).toList(),
                          )
                        : Container(
                            height: 340,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.hotel,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),

                    /// GRADIENT OVERLAY
                    Container(
                      height: 340,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.50),
                          ],
                        ),
                      ),
                    ),

                    /// BACK BUTTON
                    Positioned(
                      top: 55,
                      left: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    /// HOTEL INFO OVERLAY
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rating badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (hotel!['average_rating'] ?? 0) > 0
                                      ? (hotel!['average_rating'] as num)
                                            .toStringAsFixed(1)
                                      : 'Baru',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            hotel!['name'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  hotel!['city'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    /// DOT INDICATOR
                    if (gallery.length > 1)
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: gallery.asMap().entries.map((e) {
                            return Container(
                              width: currentImage == e.key ? 14 : 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: currentImage == e.key
                                    ? Colors.white
                                    : Colors.white54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// DESCRIPTION
                      const Text(
                        'Tentang Hotel',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        hotel!['description'] ?? '-',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 32),

                      /// FACILITIES
                      const Text(
                        'Fasilitas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _buildFacilityItems(hotel!['facilities']),
                      ),

                      const SizedBox(height: 36),

                      /// ROOMS
                      if (rooms.isNotEmpty) ...[
                        const Text(
                          'Pilihan Kamar',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Column(
                          children: rooms.map((room) {
                            final bool isSelected =
                                room['id'] == selectedRoomId;
                            final roomImage = (room['image_url'] ?? '')
                                .toString();
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => selectedRoomId = room['id']),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFEFAE0)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF5F6F52)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: buildNetworkImage(
                                        roomImage,
                                        width: 110,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        fallbackRoomId: room['id'],
                                        isRoom: true,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            room['room_type'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Kapasitas: ${room['capacity'] ?? '-'} tamu',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if ((room['description'] ?? '')
                                              .toString()
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                room['description'],
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 10),
                                          Text(
                                            formatPrice(room['price']),
                                            style: const TextStyle(
                                              color: Color(0xFF5F6F52),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      /// REVIEWS SECTION
                      const SizedBox(height: 36),
                      const Text(
                        'Ulasan Tamu',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildReviewsList(hotel!['ratings']),
                      const SizedBox(height: 36),

                      /// MAP BUTTON
                      if (mapsLat != null && mapsLng != null)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MapPage(
                                  hotelName: hotel!['name'] ?? '',
                                  latitude: mapsLat.toString(),
                                  longitude: mapsLng.toString(),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map_rounded,
                                  color: Color(0xFF5F6F52),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Lihat di Google Maps',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// ========================
          /// BOTTOM BAR
          /// ========================
          if (selectedRoom.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatPrice(selectedRoom['price']),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5F6F52),
                            ),
                          ),
                          const Text(
                            'Per malam',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReservationPage(
                              hotel: {
                                'id': hotel!['id'],
                                'image': imageUrl,
                                'image_url': imageUrl,
                                'title': hotel!['name'] ?? '',
                                'name': hotel!['name'] ?? '',
                                'location': hotel!['city'] ?? '',
                                'city': hotel!['city'] ?? '',
                                'price': formatPrice(selectedRoom['price']),
                                'room_id': selectedRoom['id'],
                                'room_type': selectedRoom['room_type'] ?? '',
                                'room_capacity': selectedRoom['capacity'],
                              },
                              selectedRoom:
                                  selectedRoom['room_type'] ?? 'Kamar',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5F6F52),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Pesan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget facilityItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF5F6F52)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  List<Widget> _buildFacilityItems(dynamic facilities) {
    // If facilities is a JSON array string or list
    List<String> items = [];
    if (facilities is List) {
      items = facilities.map((e) => e.toString()).toList();
    } else if (facilities is String && facilities.isNotEmpty) {
      try {
        final parsed = jsonDecode(facilities);
        if (parsed is List) {
          items = parsed.map((e) => e.toString()).toList();
        }
      } catch (_) {
        items = [facilities];
      }
    }

    // Map facility names to icons
    const facilityIcons = {
      'wifi': Icons.wifi_rounded,
      'wi-fi': Icons.wifi_rounded,
      'pool': Icons.pool_rounded,
      'kolam': Icons.pool_rounded,
      'restaurant': Icons.restaurant_rounded,
      'restoran': Icons.restaurant_rounded,
      'gym': Icons.fitness_center_rounded,
      'fitness': Icons.fitness_center_rounded,
      'spa': Icons.spa_rounded,
      'parking': Icons.local_parking_rounded,
      'parkir': Icons.local_parking_rounded,
      'ac': Icons.ac_unit_rounded,
      'tv': Icons.tv_rounded,
    };

    if (items.isEmpty) {
      return [
        facilityItem(Icons.wifi_rounded, 'WiFi'),
        facilityItem(Icons.pool_rounded, 'Pool'),
        facilityItem(Icons.restaurant_rounded, 'Restaurant'),
        facilityItem(Icons.local_parking_rounded, 'Parking'),
      ];
    }

    return items.map((f) {
      final key = f.toLowerCase();
      IconData icon = Icons.check_circle_outline;
      for (final entry in facilityIcons.entries) {
        if (key.contains(entry.key)) {
          icon = entry.value;
          break;
        }
      }
      return facilityItem(icon, f);
    }).toList();
  }

  Widget _buildReviewsList(dynamic ratings) {
    final List list = ratings is List ? ratings : [];
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            'Belum ada ulasan untuk hotel ini.',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Column(
      children: list.map((r) {
        final ratingVal = int.tryParse(r['rating']?.toString() ?? '5') ?? 5;
        final reviewText = (r['review'] ?? '').toString();
        final user = r['user'] as Map<String, dynamic>?;
        final userName = (user?['name'] ?? 'Tamu').toString();
        final userPic = (user?['profile_picture_url'] ?? '').toString();
        final reviewImg = (r['image_url'] ?? '').toString();

        final sanitizedUserPic = userPic.isNotEmpty
            ? (userPic.startsWith('/')
                ? '$_detailBaseUrl$userPic'
                : userPic
                    .replaceAll("http://localhost:8000", _detailBaseUrl)
                    .replaceAll("http://127.0.0.1:8000", _detailBaseUrl))
            : '';

        final sanitizedReviewImg = reviewImg.isNotEmpty
            ? (reviewImg.startsWith('/')
                ? '$_detailBaseUrl$reviewImg'
                : reviewImg
                    .replaceAll("http://localhost:8000", _detailBaseUrl)
                    .replaceAll("http://127.0.0.1:8000", _detailBaseUrl))
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF5F6F52),
                    backgroundImage: sanitizedUserPic.isNotEmpty ? NetworkImage(sanitizedUserPic) : null,
                    child: sanitizedUserPic.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star_rounded,
                              color: index < ratingVal ? Colors.amber : Colors.grey.shade300,
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (reviewText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  reviewText,
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
                ),
              ],
              if (sanitizedReviewImg.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    sanitizedReviewImg,
                    fit: BoxFit.cover,
                    height: 180,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
