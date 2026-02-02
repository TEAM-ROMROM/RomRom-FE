import 'dart:convert';
import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:romrom_fe/models/apis/responses/naver_address_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/models/location_address.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  LocationService._internal();

  /// 위치 권한 요청
  Future<bool> requestPermission() async {
    var requestStatus = await Permission.location.request();
    var status = await Permission.location.status;

    if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  /// 현재 위치 좌표 가져오기
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      log('Error getting location: $e');
      return null;
    }
  }

  /// 좌표로 주소 정보 가져오기
  Future<LocationAddress?> getAddressFromCoordinates(NLatLng position) async {
    const String naverReverseGeoCodeApiUrl = AppUrls.naverReverseGeoCodeApiUrl;
    String coords = "${position.longitude},${position.latitude}";
    const String orders = "legalcode";
    const String output = "json";

    try {
      final requestUrl = "$naverReverseGeoCodeApiUrl?coords=$coords&orders=$orders&output=$output";

      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {
          "X-NCP-APIGW-API-KEY-ID": dotenv.get('NMF_CLIENT_ID'),
          "X-NCP-APIGW-API-KEY": dotenv.get('NMF_CLIENT_SECRET'),
        },
      );

      if (response.statusCode == 200) {
        final NaverAddressResponse addressData = NaverAddressResponse.fromJson(json.decode(response.body));

        if (addressData.results.isNotEmpty) {
          final region = addressData.results[0].region;

          String siDo = region.area1.name;
          String siGunGu = region.area2.name;
          String eupMyoenDong = region.area3.name;
          String? ri = region.area4.name.isNotEmpty ? region.area4.name : null;

          return LocationAddress(
            siDo: siDo,
            siGunGu: siGunGu,
            eupMyoenDong: eupMyoenDong,
            ri: ri,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      }
      return null;
    } catch (e) {
      log("주소 요청 중 오류 발생: $e");
      return null;
    }
  }

  /// Position 객체를 NLatLng로 변환
  NLatLng positionToLatLng(Position position) {
    return NLatLng(position.latitude, position.longitude);
  }
}
