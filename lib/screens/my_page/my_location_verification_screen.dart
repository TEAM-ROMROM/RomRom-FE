import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/current_location_button.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

class MyLocationVerificationScreen extends StatefulWidget {
  const MyLocationVerificationScreen({super.key});

  @override
  State<MyLocationVerificationScreen> createState() => _MyLocationVerificationScreenState();
}

class _MyLocationVerificationScreenState extends State<MyLocationVerificationScreen> {
  final _locationService = LocationService();
  NLatLng? _currentPosition;
  String currentAdress = '';
  String siDo = '';
  String siGunGu = '';
  String eupMyoenDong = '';
  String? ri;
  final Completer<NaverMapController> mapControllerCompleter = Completer();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내 위치 인증',
        showBottomBorder: true,
        onBackPressed: () {
          Navigator.pop(context);
        },
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 맵 영역
                Expanded(
                  flex: 350,
                  child: Stack(
                    children: [
                      NaverMap(
                        options: NaverMapViewOptions(
                          initialCameraPosition: NCameraPosition(target: _currentPosition!, zoom: 15),
                          logoAlign: NLogoAlign.leftBottom,
                          logoMargin: NEdgeInsets.fromEdgeInsets(EdgeInsets.only(left: 24.w, bottom: 20.h)),
                          indoorEnable: true,
                          locationButtonEnable: false,
                          consumeSymbolTapEvents: false,
                        ),
                        forceGesture: false,
                        onMapReady: (controller) async {
                          if (!mapControllerCompleter.isCompleted) {
                            mapControllerCompleter.complete(controller);
                          }
                          await getAddressByNaverApi(_currentPosition!);
                          await controller.setLocationTrackingMode(NLocationTrackingMode.follow);
                        },
                      ),
                      // 현재 위치 버튼
                      Positioned(
                        bottom: 48.h,
                        left: 24.w,
                        child: CurrentLocationButton(
                          onTap: () async {
                            final controller = await mapControllerCompleter.future;
                            await controller.setLocationTrackingMode(NLocationTrackingMode.follow);
                          },
                          iconSize: 24.h,
                        ),
                      ),
                    ],
                  ),
                ),

                // 위치 정보 및 버튼 영역
                Expanded(
                  flex: 370,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 20.0.h),
                        Text('현재 위치가 $currentAdress 이내에 있어요', style: CustomTextStyles.p2),
                        SizedBox(height: 16.0.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 12.0.h),
                          decoration: BoxDecoration(
                            color: AppColors.locationVerificationAreaLabel,
                            borderRadius: BorderRadius.circular(100.0.r),
                          ),
                          child: Text("$siDo $siGunGu $eupMyoenDong", style: CustomTextStyles.p2),
                        ),
                        Expanded(child: Container()),
                        Padding(
                          padding: EdgeInsets.only(bottom: 76.h + MediaQuery.of(context).padding.bottom),
                          child: CompletionButton(
                            isEnabled: true,
                            buttonText: '위치 인증하기',
                            enabledOnPressed: () => _onVerifyLocationPressed(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _onVerifyLocationPressed() async {
    if (_currentPosition != null) {
      try {
        // 위치 정보가 비어있는지 확인
        if (siDo.isEmpty || siGunGu.isEmpty || eupMyoenDong.isEmpty) {
          await getAddressByNaverApi(_currentPosition!);

          if (!mounted) return;
          if (siDo.isEmpty || siGunGu.isEmpty || eupMyoenDong.isEmpty) {
            CommonSnackBar.show(context: context, message: '위치 정보를 가져오지 못했습니다. 다시 시도해주세요.', type: SnackBarType.info);
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
        if (!mounted) return;
        CommonSnackBar.show(context: context, message: '위치 인증이 완료되었습니다.', type: SnackBarType.success);
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        CommonSnackBar.show(context: context, message: '위치 저장에 실패했습니다: $e', type: SnackBarType.error);
      }
    }
  }

  // 위치 초기화 통합 메서드
  Future<void> _initializeLocation() async {
    final hasPermission = await _locationService.requestPermission();
    if (!hasPermission) return;

    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentPosition = _locationService.positionToLatLng(position);
      });
    }
  }

  // 주소 정보 로드 메서드
  Future<void> _loadAddressInfo(NLatLng position) async {
    final addressInfo = await _locationService.getAddressFromCoordinates(position);

    if (addressInfo != null) {
      setState(() {
        siDo = addressInfo.siDo;
        siGunGu = addressInfo.siGunGu;
        eupMyoenDong = addressInfo.eupMyoenDong;
        ri = addressInfo.ri;
        currentAdress = addressInfo.currentAddress;
      });
    }
  }

  // NaverMap에서 주소 가져오는 메서드를 새 메서드로 호출
  Future<void> getAddressByNaverApi(NLatLng position) async {
    await _loadAddressInfo(position);
  }
}
