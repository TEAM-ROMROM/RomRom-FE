import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:romrom_fe/screens/onboarding/category_selection_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';

// TODO : 지도 화면 리팩토링
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

  // 주소 요청 함수
  Future<void> getAddress(NLatLng position) async {
    const String apiUrl =
        "https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc";
    String coords = "${position.longitude},${position.latitude}";
    const String orders = "legalcode";
    const String output = "json";
    String apiKeyId = dotenv.get('NMF_CLIENT_ID');
    String apiKeySecret = dotenv.get('NMF_CLIENT_SECRET');

    Future<void> fetchData() async {
      final response = await http.get(
        Uri.parse("$apiUrl?coords=$coords&orders=$orders&output=$output"),
        headers: {
          "X-NCP-APIGW-API-KEY-ID": apiKeyId,
          "X-NCP-APIGW-API-KEY": apiKeySecret,
        },
      );

      if (response.statusCode == 200) {
        // JSON 응답 파싱
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          currentAdress = data["results"][0]["region"]["area3"]["name"];
        });
        log("Response Data: ${data["results"][0]["region"]["area3"]["name"]}");
      } else {
        // 요청 실패 처리
        log("Failed to load data: ${response.statusCode}");
      }
    }

    fetchData();
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
                            await getAddress(_currentPosition!); // 현재 위치 주소로 표시
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
                          onPressed: () {
                            // TODO : 위치 인증 api 연결
                            context.navigateTo(screen: const CategorySelectionScreen());
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
