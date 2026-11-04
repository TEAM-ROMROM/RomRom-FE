import 'package:flutter/foundation.dart';

/// 위경도 사각 범위 (경계 포함)
@immutable
class GeographicBounds {
  final double minimumLatitude;
  final double maximumLatitude;
  final double minimumLongitude;
  final double maximumLongitude;

  const GeographicBounds({
    required this.minimumLatitude,
    required this.maximumLatitude,
    required this.minimumLongitude,
    required this.maximumLongitude,
  });

  bool contains(double latitude, double longitude) =>
      latitude >= minimumLatitude &&
      latitude <= maximumLatitude &&
      longitude >= minimumLongitude &&
      longitude <= maximumLongitude;
}
