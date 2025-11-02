import 'package:hive/hive.dart';

part 'event_location.g.dart';

@HiveType(typeId: 2)
class EventLocation {
  @HiveField(0)
  String country;

  @HiveField(1)
  String province;

  @HiveField(2)
  String city;

  @HiveField(3)
  String district; // Kecamatan

  @HiveField(4)
  String village; // Desa/Kelurahan

  @HiveField(5)
  String rtRw;

  @HiveField(6)
  double latitude;

  @HiveField(7)
  double longitude;

  EventLocation({
    required this.country,
    required this.province,
    required this.city,
    required this.district,
    required this.village,
    required this.rtRw,
    required this.latitude,
    required this.longitude,
  });

  // Format alamat lengkap untuk display
  String get fullAddress {
    return '$village, $district, $city, $province, $country $rtRw';
  }

  // Format alamat singkat
  String get shortAddress {
    return '$city, $province';
  }

  // Mapbox URL dengan token yang benar
  String get mapboxUrl {
    return 'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/$longitude,$latitude,13,800x600@2x?access_token=REDACTED_MAPBOX_TOKEN';
  }

  // Google Maps URL sebagai fallback
  String get googleMapsUrl {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  // Untuk debugging
  @override
  String toString() {
    return 'EventLocation(city: $city, province: $province, lat: $latitude, lng: $longitude)';
  }
}