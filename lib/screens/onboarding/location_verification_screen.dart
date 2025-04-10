import 'dart:async';
import 'dart:convert';
import 'dart:developer';
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
  ㅑNLatLng? _currentPosition;
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

  // 네이버 API : 현재 주소 요청
  Future<void> getAddressByNaverApi(NLatLng position) async {
    const String naverReverseGeoCodeApiUrl = AppUrls.naverReverseGeoCodeApiUrl;
    String coords = "${position.longitude},${position.latitude}";
    const String orders = "legalcode"; // 법정동
    const String output = "json";

    try {
      final requestUrl = "$naverReverseGeoCodeApiUrl?coords=$coords&orders=$orders&output=$output";
      log("네이버 API 요청 URL: $requestUrl");
      log("네이버 API 헤더: Client ID: ${dotenv.get('NMF_CLIENT_ID').substring(0, 5)}...");

      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {
          "X-NCP-APIGW-API-KEY-ID": dotenv.get('NMF_CLIENT_ID'),
          "X-NCP-APIGW-API-KEY": dotenv.get('NMF_CLIENT_SECRET'),
        },
      );

      log("네이버 API 응답 상태 코드: ${response.statusCode}");
      log("네이버 API 응답 바디: ${response.body}");

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
        } else {
          log("응답에 결과가 없습니다.");
        }
      } else {
        log("주소 데이터 로드 실패: ${response.statusCode}, 응답: ${response.body}");
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
                await getAddressByNaverApi(_currentPosition!);
                log("onMapReady", name: "onMapReady");
                await controller.setLocationTrackingMode(
                    NLocationTrackingMode.follow);
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
                    log("위치 정보 저장 요청 파라미터:");
                    log("longitude: ${_currentPosition!.longitude}");
                    log("latitude: ${_currentPosition!.latitude}");
                    log("siDo: $siDo");
                    log("siGunGu: $siGunGu");
                    log("eupMyoenDong: $eupMyoenDong");
                    log("ri: $ri");

                    // 위치 정보가 비어있는지 확인
                    if (siDo.isEmpty || siGunGu.isEmpty || eupMyoenDong.isEmpty) {
                      log("위치 정보 누락: 주소 정보가 정상적으로 로드되지 않았습니다.");
                      // 네이버 API를 다시 호출하여 위치 정보 업데이트 시도
                      await getAddressByNaverApi(_currentPosition!);

                      // 여전히 비어있다면 사용자에게 알림
                      if (siDo.isEmpty || siGunGu.isEmpty || eupMyoenDong.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('위치 정보를 가져오지 못했습니다. 다시 시도해주세요.')),
                          );
                        }
                        return;
                      }
                    }

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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('위치 저장에 실패했습니다: $e')),
                      );
                    }
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

