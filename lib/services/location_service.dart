import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/models/apis/responses/naver_address_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/address_lookup_cache.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  LocationService._internal();

  // 역지오코딩 응답 대기 상한 (5초)
  static const Duration reverseGeocodeTimeout = Duration(seconds: 5);

  // 역지오코딩 공용 연결 (요청마다 새 연결 생성 방지)
  final http.Client _httpClient = http.Client();
  late final AddressLookupCache _addressLookupCache = AddressLookupCache(fetchAddress: _fetchAddressFromNaver);

  /// 위치 권한 요청
  Future<bool> requestPermission() async {
    // geolocator API 사용: permission_handler와 충돌 방지
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// 현재 위치 권한 상태 확인 (시스템 팝업 없이)
  Future<bool> checkPermissionStatus() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
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

  /// 좌표로 주소 정보 가져오기 (캐시·진행 중 요청 공유 경유, 실패 시 null)
  Future<LocationAddress?> getAddressFromCoordinates(NLatLng position) {
    return _addressLookupCache.lookup(position.latitude, position.longitude);
  }

  /// 네이버 역지오코딩 1회 호출: 좌표 > 주소 (non-200·결과 없음 > null, 예외는 캐시가 null 처리)
  Future<LocationAddress?> _fetchAddressFromNaver(double latitude, double longitude) async {
    const String naverReverseGeoCodeApiUrl = AppUrls.naverReverseGeoCodeApiUrl;
    String coords = "$longitude,$latitude";
    const String orders = "legalcode";
    const String output = "json";

    final requestUrl = "$naverReverseGeoCodeApiUrl?coords=$coords&orders=$orders&output=$output";

    // 타임아웃 시 TimeoutException > 캐시가 null 처리 (진행 중 요청 영구 고착 방지)
    final response = await _httpClient
        .get(
          Uri.parse(requestUrl),
          headers: {
            "X-NCP-APIGW-API-KEY-ID": dotenv.get('NMF_CLIENT_ID'),
            "X-NCP-APIGW-API-KEY": dotenv.get('NMF_CLIENT_SECRET'),
          },
        )
        .timeout(reverseGeocodeTimeout);

    if (response.statusCode != 200) return null;

    final NaverAddressResponse addressData = NaverAddressResponse.fromJson(json.decode(response.body));
    if (addressData.results.isEmpty) return null;

    final region = addressData.results[0].region;
    return LocationAddress(
      siDo: region.area1.name,
      siGunGu: region.area2.name,
      eupMyoenDong: region.area3.name,
      ri: region.area4.name.isNotEmpty ? region.area4.name : null,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Position 객체를 NLatLng로 변환
  NLatLng positionToLatLng(Position position) {
    return NLatLng(position.latitude, position.longitude);
  }
}
