import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static double? userLatitude;
  static double? userLongitude;
  static bool hasGps = false;

  // Calculates the distance between two coordinates in kilometers using the Haversine formula.
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // Radius of the Earth in km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c; // Distance in km
  }

  static double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  // Gets default coordinates for a city to use as a fallback.
  static Map<String, double> getCityCenter(String city) {
    final c = city.toLowerCase().trim();
    if (c.contains("jakarta")) {
      return {"latitude": -6.2087634, "longitude": 106.845599};
    }
    if (c.contains("bali")) {
      return {"latitude": -8.6500, "longitude": 115.2167};
    }
    if (c.contains("yogyakarta") || c.contains("jogja")) {
      return {"latitude": -7.7956, "longitude": 110.3695};
    }
    // Default to Bandung center
    return {"latitude": -6.9174639, "longitude": 107.6191228};
  }

  // Initializes user location coordinates
  static Future<void> initLocation(String selectedCity) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallback(selectedCity);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallback(selectedCity);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallback(selectedCity);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      userLatitude = position.latitude;
      userLongitude = position.longitude;
      hasGps = true;
    } catch (e) {
      debugPrint("Geolocator error, using fallback: $e");
      _useFallback(selectedCity);
    }
  }

  static void _useFallback(String selectedCity) {
    final center = getCityCenter(selectedCity);
    userLatitude = center["latitude"];
    userLongitude = center["longitude"];
    hasGps = false;
  }
}
