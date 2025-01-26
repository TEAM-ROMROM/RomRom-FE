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
                    child: CircularProgressIndicator(), // 로딩 스피너
                  )
                : NaverMap(
                    options: NaverMapViewOptions(
                      initialCameraPosition: NCameraPosition(
                        target: _currentPosition!, // null이 아님을 보장
                        zoom: 15,
                      ),
                      indoorEnable: true, // 실내 맵 사용 가능 여부 설정
                      locationButtonEnable: true, // 위치 버튼 표시 여부 설정
                      consumeSymbolTapEvents: false, // 심볼 탭 이벤트 소비 여부 설정
                    ),
                    onMapReady: (controller) async {
                      mapControllerCompleter.complete(controller);
                      log("onMapReady", name: "onMapReady");

                      // 위치 추적 모드 활성화
                      await controller.setLocationTrackingMode(
                          NLocationTrackingMode.follow);
                    },
                  ),
      ),
    );
  }
}
