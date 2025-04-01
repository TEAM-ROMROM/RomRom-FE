import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:romrom_fe/models/app_urls.dart';

import 'package:romrom_fe/screens/onboarding/category_selection_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/models/apis/responses/naver_address_response.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

/// 위치 인증 화면
class LocationVerificationScreen extends StatefulWidget {
  const LocationVerificationScreen({super.key});

  @override
  State<LocationVerificationScreen> createState() => _LocationVerificationScreenState();
}

class _LocationVerificationScreenState extends State<LocationVerificationScreen> {
  late NaverMapController _mapController;
  NLatLng? _currentPosition;
  String currentAdress = '';

  // 위치 정보 저장
  String siDo = '';
  String siGunGu = '';
  String eupMyoenDong = '';
  String? ri;

  @override
  void initState() {
    super.initState();
    _permission();
  }

  // 위치 권한 요청
  void _permission() async {
    var requestStatus = await Permission.location.request();
    var status = await Permission.location.status;
    if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      await _getCurrentPosition();
    }
  }

  // 현재 위치 불러오는 함수
  Future<void> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = NLatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      log('Error getting location: $e');
    }
  }

  // marker 추가 함수
  void _addMarker(NLatLng position) {
    // 추가할 마커 커스텀
    final newNMarker = NMarker(
      id: '${DateTime.timestamp()}',
      position: position, // 마커 위치
      size: const Size(32, 45),
    );

    setState(() {
      _mapController.addOverlay(newNMarker);
    });
  }

  // 네이버 API : 현재 주소 요청
  Future<void> getAddressByNaverApi(NLatLng position) async {
    const String naverReverseGeoCodeApiUrl = AppUrls.naverReverseGeoCodeApiUrl;
    String coords = "${position.longitude},${position.latitude}";
    const String orders = "legalcode"; // 법정동
    const String output = "json";

    try {
      final response = await http.get(
        Uri.parse("$naverReverseGeoCodeApiUrl?coords=$coords&orders=$orders&output=$output"),
        headers: {
          "X-NCP-APIGW-API-KEY-ID": dotenv.get('NMF_CLIENT_ID'),
          "X-NCP-APIGW-API-KEY": dotenv.get('NMF_CLIENT_SECRET'),
        },
      );

      if (response.statusCode == 200) {
        final NaverAddressResponse addressData = NaverAddressResponse.fromJson(json.decode(response.body));

        // 주소 데이터가 존재하는 경우
        if (addressData.results.isNotEmpty) {
          final region = addressData.results[0].region;

          setState(() {
            siDo = region.area1.name;
            siGunGu = region.area2.name;
            eupMyoenDong = region.area3.name;
            ri = region.area4.name.isNotEmpty ? region.area4.name : null;

            currentAdress = eupMyoenDong;
          });

          log("주소 데이터: $siDo $siGunGu $eupMyoenDong ${ri ?? ''}");
        }
      } else {
        log("주소 데이터 로드 실패: ${response.statusCode}");
      }
    } catch (e) {
      log("주소 요청 중 오류 발생: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // NaverMapController 객체의 비동기 작업 완료를 나타내는 Completer 생성
    final Completer<NaverMapController> mapControllerCompleter = Completer();

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('동네 인증하기'),
        ),
        body: // 현재 위치를 가져오기 전이라면 로딩 화면 표시
        _currentPosition == null
            ? const Center(
          child: CircularProgressIndicator(), // 로딩 인디케이터
        )
            : Flex(
          direction: Axis.vertical,
          children: [
            Flexible(
              flex: 2,
              child: NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: _currentPosition!,
                    zoom: 15,
                  ),
                  indoorEnable: true, // 실내 맵 사용 가능 여부 설정
                  locationButtonEnable: true, // 위치 버튼 표시 여부 설정
                  consumeSymbolTapEvents: false, // 심볼 탭 이벤트 소비 여부 설정
                ),
                onMapReady: (controller) async {
                  mapControllerCompleter.complete(controller);
                  _mapController = controller;
                  await getAddressByNaverApi(_currentPosition!); // 현재 위치 주소로 표시
                  log("onMapReady", name: "onMapReady");

                  // 위치 추적 모드 활성화
                  await controller.setLocationTrackingMode(
                      NLocationTrackingMode.follow);
                },
                onMapTapped: (point, latLng) async {
                  log("Map tapped at: $latLng", name: "MapTapEvent");
                  _addMarker(latLng); // 지도에 마커 추가
                },
              ),
            ),
            Flexible(
              flex: 3,
              // ignore: avoid_unnecessary_containers
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 16.0),
                        width: double.maxFinite,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F3F7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                            '현재 위치가 내 동네로 설정한 \'$currentAdress\'내에 있어요'),
                      ),
                    ),

                  ],
                ),
              ),
            ),
            Flexible(
              flex: 1,
              child: TextButton(
                child: const Text('위치 인증하기'),
                onPressed: () async {
                  if (_currentPosition != null) {
                    try {
                      // 위치 정보 저장
                      await MemberApi().saveMemberLocation(
                        longitude: _currentPosition!.longitude,
                        latitude: _currentPosition!.latitude,
                        siDo: siDo,
                        siGunGu: siGunGu,
                        eupMyoenDong: eupMyoenDong,
                        ri: ri,
                      );
                      if (context.mounted) {
                        // 물품 선호 카테고리 선택 화면 이동
                        context.navigateTo(screen: const CategorySelectionScreen());
                      }
                    } catch (e) {
                      log("위치 정보 저장 실패: $e");
                      // 에러 처리 (필요시 사용자에게 알림)
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
