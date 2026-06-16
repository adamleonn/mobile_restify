import 'package:flutter/material.dart';
import 'config.dart';

String getHotelFallbackImage(dynamic id) {
  final images = [
    'Puteri-Gunung-Hotel.jpg',
    'Hotel-Savoy-Homann-Bandung.jpg',
    'Ivory-Hotel-Bandung.jpg',
    'Mutiara-Hotel-and-Convention-Bandung.jpg',
    'Urbanview-Hotel-Grand-Malabar-Bandung.jpg',
    'aryaduta-bandung.jpg',
    'Hilton-Bandung.jpg',
    'Mercure-Bandung-City-Centre.jpg'
  ];
  int numId = 0;
  if (id is num) {
    numId = id.toInt();
  } else if (id is String) {
    numId = int.tryParse(id) ?? 0;
  }
  return '${Config.baseUrl}/images/HotelImages/${images[numId % images.length]}';
}

String getRoomFallbackImage({dynamic roomId}) {
  final images = [
    'room_main.jpg',
    'room_detail1.jpg',
    'room_detail2.jpg',
    'room_detail3.jpg',
    'room_detail4.jpg',
    'room_detail5.jpg',
  ];
  int numId = 0;
  if (roomId is num) {
    numId = roomId.toInt();
  } else if (roomId is String) {
    numId = int.tryParse(roomId) ?? 0;
  }
  return '${Config.baseUrl}/images/room/${images[numId % images.length]}';
}

Widget buildNetworkImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  dynamic fallbackHotelId,
  dynamic fallbackRoomId,
  bool isRoom = false,
}) {
  final isSeedHotel = url.contains('/storage/hotels/');
  final isSeedRoom = url.contains('/storage/rooms/') && (
    url.contains('deluxe-room.jpg') ||
    url.contains('superior-room.jpg') ||
    url.contains('standard-room.jpg') ||
    url.contains('executive-room.jpg')
  );

  if (url.isEmpty || isSeedHotel || isSeedRoom) {
    return _buildErrorPlaceholder(width, height, isRoom, fallbackHotelId, fallbackRoomId);
  }

  return Image.network(
    url,
    width: width,
    height: height,
    fit: fit,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade100,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    },
    errorBuilder: (context, error, stackTrace) {
      return _buildErrorPlaceholder(width, height, isRoom, fallbackHotelId, fallbackRoomId);
    },
  );
}

Widget _buildErrorPlaceholder(
  double? width,
  double? height,
  bool isRoom,
  dynamic fallbackHotelId,
  dynamic fallbackRoomId,
) {
  final fallbackUrl = isRoom
      ? getRoomFallbackImage(roomId: fallbackRoomId)
      : getHotelFallbackImage(fallbackHotelId);
      
  return Image.network(
    fallbackUrl,
    width: width,
    height: height,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade100,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    },
    errorBuilder: (context, error, stackTrace) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            isRoom ? Icons.hotel : Icons.broken_image,
            color: Colors.grey,
          ),
        ),
      );
    },
  );
}
