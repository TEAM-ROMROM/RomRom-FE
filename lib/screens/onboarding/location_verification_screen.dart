import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/screens/onboarding/category_selection_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/models/apis/responses/naver_address_response.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

/// 위치 인증 화면
class LocationVerificationScreen extends StatefulWidget {
  const LocationVerificationScreen({super.key});

  @override
  State<LocationVerificationScreen> createState() =>
      _LocationVerificationScreenState();
}

class _LocationVerificationScreenState
    extends State<LocationVerificationScreen> {
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

  // 커스텀 마커 생성 함수 (숫자 포함)
  Future<NOverlayImage> _createNumberedMarkerIcon(int number) async {
    // 숫자가 포함된 커스텀 마커 이미지를 생성
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = Colors.yellow;
    final textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 원형 마커 배경
    canvas.drawCircle(const Offset(25, 25), 25, paint);
    // 숫자 텍스트를 중앙에 배치
    textPainter.paint(canvas, const Offset(25 - 10, 25 - 10));

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(50, 50);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return NOverlayImage.fromByteArray(buffer);
  }

  // 마커 추가 함수
  void _addMarker(NLatLng position, {int? number}) async {
    final marker = NMarker(
      id: number != null ? 'marker_$number' : '${DateTime.timestamp()}',
      position: position,
      size: const Size(32, 45),
    );

    // 숫자가 있으면 커스텀 마커로 설정
    if (number != null) {
      final icon = await _createNumberedMarkerIcon(number);
      marker.setIcon(icon);
    }

    setState(() {
      _mapController.addOverlay(marker);
    });
  }

  // 주변 POI에 마커 추가 (예시 위치)
  void _addNearbyMarkers() async {
    if (_currentPosition == null) return;

    // 현재 위치를 기준으로 주변에 마커를 추가 (예시 좌표)
    final nearbyPositions = [
      NLatLng(_currentPosition!.latitude + 0.001, _currentPosition!.longitude + 0.001),
      NLatLng(_currentPosition!.latitude - 0.001, _currentPosition!.longitude - 0.001),
      NLatLng(_currentPosition!.latitude + 0.002, _currentPosition!.longitude - 0.002),
      NLatLng(_currentPosition!.latitude - 0.002, _currentPosition!.longitude + 0.002),
    ];

    for (int i = 0; i < nearbyPositions.length; i++) {
      _addMarker(nearbyPositions[i], number: i + 1);
    }
  }

  // 네이버 API : 현재 주소 요청
  Future<void> getAddressByNaverApi(NLatLng position) async {
    const String naverReverseGeoCodeApiUrl = AppUrls.naverReverseGeoCodeApiUrl;
    String coords = "${position.longitude},${position.latitude}";
    const String orders = "legalcode"; // 법정동
    const String output = "json";

    try {
      final response = await http.get(
        Uri.parse(
            "$naverReverseGeoCodeApiUrl?coords=$coords&orders=$orders&output=$output"),
        headers: {
          "X-NCP-APIGW-API-KEY-ID": dotenv.get('NMF_CLIENT_ID'),
          "X-NCP-APIGW-API-KEY": dotenv.get('NMF_CLIENT_SECRET'),
        },
      );

      if (response.statusCode == 200) {
        final NaverAddressResponse addressData =
        NaverAddressResponse.fromJson(json.decode(response.body));

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
    final Completer<NaverMapController> mapControllerCompleter = Completer();

    return Scaffold(
      appBar: AppBar(
        title: const Text('동네 인증하기'),
      ),
      body: _currentPosition == null
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          Expanded(
            flex: 3,
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: _currentPosition!,
                  zoom: 15,
                ),
                indoorEnable: true,
                locationButtonEnable: true,
                consumeSymbolTapEvents: false,
              ),
              onMapReady: (controller) async {
                mapControllerCompleter.complete(controller);
                _mapController = controller;
                await getAddressByNaverApi(_currentPosition!);
                log("onMapReady", name: "onMapReady");
                await controller.setLocationTrackingMode(
                    NLocationTrackingMode.follow);

                // 현재 위치에 기본 마커 추가
                _addMarker(_currentPosition!);
                // 주변 POI 마커 추가
                _addNearbyMarkers();
              },
              onMapTapped: (point, latLng) async {
                log("Map tapped at: $latLng", name: "MapTapEvent");
                _addMarker(latLng);
              },
            ),
          ),
          const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '현재 위치가 내 동네로 설정한 \'$currentAdress\'내에 있어요',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '현재 위치가 내 동네로 설정한 \'$currentAdress\' 내에 있어요',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryBlack,
                foregroundColor: AppColors.textColorBlack,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
              ),
              onPressed: () async {
                if (_currentPosition != null) {
                  try {
                    await MemberApi().saveMemberLocation(
                      longitude: _currentPosition!.longitude,
                      latitude: _currentPosition!.latitude,
                      siDo: siDo,
                      siGunGu: siGunGu,
                      eupMyoenDong: eupMyoenDong,
                      ri: ri,
                    );
                    if (context.mounted) {
                      context.navigateTo(
                          screen: const CategorySelectionScreen());
                    }
                  } catch (e) {
                    log("위치 정보 저장 실패: $e");
                  }
                }
              },
              child: const Text('위치 인증하기'),
            ),
          ),
        ],
      ),
    );
  }
}