import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as location_pkg;

class LocationService {
  final location_pkg.Location _location = location_pkg.Location();
  bool _serviceEnabled = false;
  location_pkg.PermissionStatus? _permissionGranted;

  Future<bool> initialize() async {
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return false;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == location_pkg.PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
    }

    if (_permissionGranted != location_pkg.PermissionStatus.granted &&
        _permissionGranted != location_pkg.PermissionStatus.grantedLimited) {
      return false;
    }

    return true;
  }

  Future<location_pkg.LocationData?> getCurrentLocation() async {
    try {
      return await _location.getLocation();
    } catch (e) {
      return null;
    }
  }

  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.country}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<location_pkg.LocationData> get locationStream =>
      _location.onLocationChanged;
}
