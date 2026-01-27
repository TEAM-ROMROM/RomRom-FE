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

class LocationVerificationStep extends StatefulWidget {
  final VoidCallback onNext;

  const LocationVerificationStep({super.key, required this.onNext});

  @override
  State<LocationVerificationStep> createState() =>
      _LocationVerificationStepState();
}

class _LocationVerificationStepState extends State<LocationVerificationStep> {
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
    if (_currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 맵 영역
        Expanded(
          flex: 350,
          child: Stack(
            children: [
              NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: _currentPosition!,
                    zoom: 15,
                  ),
                  logoAlign: NLogoAlign.leftBottom,
                  logoMargin: NEdgeInsets.fromEdgeInsets(
                    EdgeInsets.only(left: 24.w, bottom: 20.h),
                  ),
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
                  await controller.setLocationTrackingMode(
                    NLocationTrackingMode.follow,
                  );
                },
              ),
              // 현재 위치 버튼
              Positioned(
                bottom: 48.h,
                left: 24.w,
                child: CurrentLocationButton(
                  onTap: () async {
                    final controller = await mapControllerCompleter.future;
                    await controller.setLocationTrackingMode(
                      NLocationTrackingMode.follow,
                    );
                  },
                  iconSize: 24.h,
                ),
              ),
            ],
          ),
        ),

        // 위치 정보 및 버튼 영역
        Expanded(
          flex: 285,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20.0.h),
                Text(
                  '현재 위치가 $currentAdress 이내에 있어요',
                  style: CustomTextStyles.p2,
                ),
                SizedBox(height: 16.0.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0.w,
                    vertical: 12.0.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.locationVerificationAreaLabel,
                    borderRadius: BorderRadius.circular(100.0.r),
                  ),
                  child: Text(
                    "$siDo $siGunGu $eupMyoenDong",
                    style: CustomTextStyles.p2,
                  ),
                ),
                Expanded(child: Container()),
                // 완료 버튼 - CategoryCompletionButton 위젯으로 변경
                Padding(
                  padding: EdgeInsets.only(bottom: 63.h + MediaQuery.of(context).padding.bottom),
                  child: Center(
                    child: CompletionButton(
                      isEnabled: true,
                      enabledOnPressed: () => _onVerifyLocationPressed(),
                      buttonText: '위치 인증하기',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
            CommonSnackBar.show(
              context: context,
              message: '위치 정보를 가져오지 못했습니다. 다시 시도해주세요.',
              type: SnackBarType.info,
            );
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

        // 다음 단계로 이동
        widget.onNext();
      } catch (e) {
        if (!mounted) return;
        CommonSnackBar.show(
          context: context,
          message: '위치 저장에 실패했습니다: $e',
          type: SnackBarType.error,
        );
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
    final addressInfo = await _locationService.getAddressFromCoordinates(
      position,
    );

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
