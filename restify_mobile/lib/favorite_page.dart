import 'package:flutter/material.dart';
import 'detail_hotel_page.dart';
import 'home_page.dart';
import 'image_utils.dart';
import 'location_service.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Map<String, dynamic>> get favoriteList {
    return favoriteHotels.map((name) {
      return favoriteHotelDetails[name] ?? {'name': name};
    }).toList()..sort(
      (a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo(
        (b['name'] ?? '').toString().toLowerCase(),
      ),
    );
  }

  String formatPrice(dynamic price) {
    final value = double.tryParse(price.toString()) ?? 0;
    if (value == 0) return 'Harga belum tersedia';

    final parts = value.toStringAsFixed(0).split('');
    final result = StringBuffer();

    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.write('.');
      result.write(parts[i]);
    }

    return 'Rp ${result.toString()}';
  }

  void removeFavorite(String hotelName) {
    setState(() {
      favoriteHotels.remove(hotelName);
      favoriteHotelDetails.remove(hotelName);
      favoriteVersion.value++;
    });
    saveFavorites();
  }

  void openHotelDetail(Map<String, dynamic> hotel) {
    final hotelId = hotel['id'];
    if (hotelId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HotelDetailPage(hotelId: hotelId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red.shade400, size: 30),
                  const SizedBox(width: 10),
                  const Text(
                    "Favorite",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Hotel yang kamu simpan",
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: favoriteVersion,
                  builder: (context, value, child) {
                    final hotels = favoriteList;

                    return hotels.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: 90,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Belum Ada Favorit",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Simpan hotel favoritmu terlebih dahulu",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: hotels.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final hotel = hotels[index];
                              final name = (hotel['name'] ?? '').toString();
                              final image = (hotel['image_url'] ?? '')
                                  .toString();
                              final city = (hotel['city'] ?? 'Unknown')
                                  .toString();
                              final rating =
                                  double.tryParse(
                                    (hotel['average_rating'] ?? '0').toString(),
                                  )?.toStringAsFixed(1) ??
                                  '0.0';
                              final price = formatPrice(hotel['lowest_price']);

                              return favoriteHotelCard(
                                hotel: hotel,
                                image: image,
                                name: name,
                                city: city,
                                rating: rating,
                                price: price,
                              );
                            },
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget favoriteHotelCard({
    required Map<String, dynamic> hotel,
    required String image,
    required String name,
    required String city,
    required String rating,
    required String price,
  }) {
    final double? hotelLat = double.tryParse(hotel['latitude']?.toString() ?? '');
    final double? hotelLon = double.tryParse(hotel['longitude']?.toString() ?? '');
    String? distanceStr;
    if (hotelLat != null && hotelLon != null && LocationService.userLatitude != null && LocationService.userLongitude != null) {
      final dist = LocationService.calculateDistance(
        LocationService.userLatitude!,
        LocationService.userLongitude!,
        hotelLat,
        hotelLon,
      );
      distanceStr = '${dist.toStringAsFixed(1)} km';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => openHotelDetail(hotel),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: buildNetworkImage(
                image,
                width: 92,
                height: 92,
                fit: BoxFit.cover,
                fallbackHotelId: hotel['id'],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 15,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: city,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              if (distanceStr != null) ...[
                                TextSpan(
                                  text: ' • ',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                TextSpan(
                                  text: distanceStr,
                                  style: const TextStyle(
                                    color: Color(0xFF5F6F52),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          price,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF5F6F52),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => removeFavorite(name),
              icon: const Icon(Icons.favorite, color: Colors.red),
              tooltip: "Hapus dari favorit",
            ),
          ],
        ),
      ),
    );
  }
}
