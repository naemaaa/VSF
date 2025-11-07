// event_location.dart
import 'package:hive/hive.dart';

part 'event_location.g.dart';

@HiveType(typeId: 2)
class EventLocationModel {
  @HiveField(0) final String country;
  @HiveField(1) final String province;
  @HiveField(2) final String city;
  @HiveField(3) final String district; 
  @HiveField(4) final String village; 
  @HiveField(6) final double latitude;
  @HiveField(7) final double longitude;

  const EventLocationModel({
    required this.country,
    required this.province,
    required this.city,
    required this.district,
    required this.village,
    required this.latitude,
    required this.longitude,
  });

  String get fullAddress {
    return '$village, $district, $city, $province, $country ';
  }

  String get shortAddress {
    return '$city, $province';
  }

  String get mapboxUrl {
    if (latitude == 0.0 && longitude == 0.0) return '';
    return 'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/$longitude,$latitude,13,800x600@2x?access_token=REDACTED_MAPBOX_TOKEN';
  }

  String get googleMapsUrl {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  @override
  String toString() {
    return 'EventLocationModel(city: $city, province: $province, lat: $latitude, lng: $longitude)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventLocationModel &&
          runtimeType == other.runtimeType &&
          country == other.country &&
          province == other.province &&
          city == other.city; 
          
  @override
  int get hashCode => country.hashCode ^ province.hashCode ^ city.hashCode;
}