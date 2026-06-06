import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Fetches the device's current GPS position and reverse-geocodes it into
/// a human-readable address string.
///
/// `geolocator` is cross-platform (mobile + web). `geocoding` is
/// mobile-only — on web/desktop calling it throws MissingPluginException,
/// so the web build falls back to BigDataCloud's free `reverse-geocode-
/// client` endpoint (no API key, no rate limit for client-side use).
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

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
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

  Future<String> _reverseGeocode(double lat, double lng) async {
    // `geocoding` package has no web implementation — it'd throw
    // MissingPluginException in a browser. Route web through the HTTP
    // fallback instead.
    if (kIsWeb) return _reverseGeocodeViaHttp(lat, lng);
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return _fallbackCoords(lat, lng);
      final p = placemarks.first;
      final parts = <String>{};
      for (final field in [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ]) {
        if (field != null && field.trim().isNotEmpty) parts.add(field.trim());
      }
      return parts.isEmpty ? _fallbackCoords(lat, lng) : parts.join(', ');
    } catch (e) {
      debugPrint('🚨 LocationService._reverseGeocode (native): $e');
      return _fallbackCoords(lat, lng);
    }
  }

  /// Web-only reverse-geocoder. BigDataCloud's `reverse-geocode-client`
  /// endpoint is keyless and free for client-side use, so this works
  /// straight from `flutter run -d chrome` with no setup.
  Future<String> _reverseGeocodeViaHttp(double lat, double lng) async {
    try {
      final dio = Dio();
      final res = await dio.get<Map<String, dynamic>>(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'localityLanguage': 'en',
        },
      );
      final data = res.data;
      if (data == null) return _fallbackCoords(lat, lng);
      final parts = <String>{};
      for (final key in const [
        'locality',
        'city',
        'principalSubdivision',
        'countryName',
      ]) {
        final v = data[key];
        if (v is String && v.trim().isNotEmpty) parts.add(v.trim());
      }
      return parts.isEmpty ? _fallbackCoords(lat, lng) : parts.join(', ');
    } catch (e) {
      debugPrint('🚨 LocationService._reverseGeocodeViaHttp: $e');
      return _fallbackCoords(lat, lng);
    }
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
