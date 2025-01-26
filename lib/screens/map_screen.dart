import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late NaverMapController _mapController;
  NLatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _permission();
  }

  void _permission() async {
    var requestStatus = await Permission.location.request();
    var status = await Permission.location.status;
    if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      await _getCurrentPosition();
    }
  }

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
                            log("onMapReady", name: "onMapReady");

                            // 위치 추적 모드 활성화
                            await controller.setLocationTrackingMode(
                                NLocationTrackingMode.follow);
                          },
                          onMapTapped: (point, latLng) {
                            log("Map tapped at: $latLng", name: "MapTapEvent");
                            _addMarker(latLng);
                          },
                        ),
                      ),
                      Flexible(
                        flex: 3,
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
                                  child: const Text(
                                      '현재 위치가 내 동네로 설정한 \'군자동\'내에 있어요'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
