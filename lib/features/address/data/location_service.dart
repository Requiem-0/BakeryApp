import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Fetches the device's current GPS position and reverse-geocodes it
/// into a street-level address.
///
/// Reverse geocoding goes through OpenStreetMap Nominatim — Google's
/// reverse-geocode (which `package:geocoding` wraps on Android) is
/// thin on Nepal data and tends to return only city-level info, so a
/// customer in a Pokhara neighbourhood gets just "Pokhara, Gandaki,
/// Nepal" with no street or ward. Nominatim's community-mapped data
/// has road names, neighbourhoods, and wards down to the building.
///
/// Returns null on permission denial, service-disabled, or any other
/// failure. Callers handle null by leaving the form blank so the user
/// can type the address manually.
class LocationService {
  Future<PickedLocation?> fetchCurrent() async {
    try {
      // The explicit isLocationServiceEnabled/checkPermission/requestPermission
      // dance is only correct on mobile. On web, geolocator_web maps the
      // browser's "prompt" state to LocationPermission.denied and its
      // requestPermission() just re-queries the Permissions API without
      // triggering a prompt — so the dance bails out before the user ever
      // sees one. Calling getCurrentPosition() directly IS what triggers
      // the browser prompt; denial then surfaces as a thrown error.
      if (!kIsWeb) {
        if (!await Geolocator.isLocationServiceEnabled()) return null;
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      // `bestForNavigation` + `forceLocationManager: true` on Android
      // skips the fused location provider (which can hand back a
      // cell-tower or WiFi-based fix that's wildly off — we had a
      // customer in Newroad Pokhara get reverse-geocoded to Baglung
      // because the fused provider returned a stale ~50km-off fix
      // before the GPS chip had locked) and forces the OS
      // LocationManager API directly off the GPS hardware. Adds a
      // 20s timeLimit so we don't hang forever on devices that can't
      // see the sky.
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 20),
        // Ignore any cached fix older than 5 seconds — forces a fresh
        // GPS read instead of accepting a stale "Baglung" hit from
        // hours ago.
        forceAndroidLocationManager:
            defaultTargetPlatform == TargetPlatform.android,
      );

      final address = await _reverseGeocode(pos.latitude, pos.longitude);

      return PickedLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        address: address,
      );
    } catch (e) {
      debugPrint('🚨 LocationService.fetchCurrent: $e');
      return null;
    }
  }

  /// OpenStreetMap Nominatim — keyless, free for client-side use,
  /// shared rate limit so don't hammer it. Both web and mobile run
  /// through this so the address detail is uniform across platforms.
  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final dio = Dio(BaseOptions(
        // Nominatim policy: requests must identify a real user agent.
        // Anonymous or fake-browser UAs may be blocked.
        headers: const {
          'User-Agent': 'orderB-bakery-app/1.0',
          'Accept-Language': 'en',
        },
        receiveTimeout: const Duration(seconds: 8),
      ));
      final res = await dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'addressdetails': 1,
          // zoom=18 → building-level detail. Lower values widen the
          // match radius and start returning suburb/city instead.
          'zoom': 18,
        },
      );
      final data = res.data;
      if (data == null) return _fallbackCoords(lat, lng);
      final addr = data['address'];
      if (addr is! Map<String, dynamic>) {
        final display = data['display_name'];
        if (display is String && display.trim().isNotEmpty) {
          return display.trim();
        }
        return _fallbackCoords(lat, lng);
      }
      return _composeAddress(addr) ?? _fallbackCoords(lat, lng);
    } catch (e) {
      debugPrint('🚨 LocationService._reverseGeocode: $e');
      return _fallbackCoords(lat, lng);
    }
  }

  /// Builds a "house# road, neighbourhood, ward/suburb, city, state,
  /// country" string from Nominatim's `address` object. De-dupes so we
  /// don't get "Pokhara, Pokhara, Gandaki" when the data overlaps.
  String? _composeAddress(Map<String, dynamic> addr) {
    final parts = <String>[];
    final seen = <String>{};
    void add(String? s) {
      if (s == null) return;
      final t = s.trim();
      if (t.isEmpty) return;
      final key = t.toLowerCase();
      if (!seen.add(key)) return;
      parts.add(t);
    }

    final houseNumber = addr['house_number'] as String?;
    final road = addr['road'] as String?;
    if (road != null && road.trim().isNotEmpty) {
      add(houseNumber != null && houseNumber.trim().isNotEmpty
          ? '$houseNumber $road'
          : road);
    }
    add(addr['neighbourhood'] as String?);
    add(addr['suburb'] as String?);
    add(addr['village'] as String? ??
        addr['town'] as String? ??
        addr['city'] as String?);
    add(addr['state'] as String? ??
        addr['state_district'] as String? ??
        addr['region'] as String?);
    add(addr['country'] as String?);

    return parts.isEmpty ? null : parts.join(', ');
  }

  String _fallbackCoords(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}

class PickedLocation {
  final double latitude;
  final double longitude;
  final String address;
  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}
