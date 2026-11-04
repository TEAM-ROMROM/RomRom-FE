import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/location_verification/location_recheck_text_button.dart';
import 'package:shadex/shadex.dart';

/// 서비스 지역 밖 동네 선택: 안내 문구 + 움직이는 지도(중앙 핀 = 선택 위치) + 선택 동네 + 인증 버튼·다시 확인
/// 실제 GPS가 대한민국 밖일 때만 노출 (국내는 GPS 위치만 인증)
class LocationVerificationManualSelectionView extends StatefulWidget {
  // 대한민국 전체가 보이는 시작 위치·확대 수준
  static const NLatLng koreaCenterPosition = NLatLng(36.5, 127.5);
  static const double koreaOverviewZoomLevel = 6.5;

  final Future<LocationAddress?> Function(double latitude, double longitude) lookupAddress;
  final bool isSaving;
  final void Function(NLatLng position, LocationAddress address) onVerifyPressed;
  final VoidCallback onRecheckPressed;

  const LocationVerificationManualSelectionView({
    super.key,
    required this.lookupAddress,
    required this.isSaving,
    required this.onVerifyPressed,
    required this.onRecheckPressed,
  });

  @override
  State<LocationVerificationManualSelectionView> createState() => _LocationVerificationManualSelectionViewState();
}

class _LocationVerificationManualSelectionViewState extends State<LocationVerificationManualSelectionView> {
  final Completer<NaverMapController> _mapControllerCompleter = Completer();
  NLatLng? _selectedPosition;
  LocationAddress? _selectedAddress;
  // 마지막 주소 조회 번호 (지도 연속 이동 시 늦게 온 이전 응답 무시)
  int _addressLookupToken = 0;

  /// 지도 멈춤 > 중앙 좌표 동네 조회 (최신 조회만 반영)
  Future<void> _onCameraIdle() async {
    final controller = await _mapControllerCompleter.future;
    final cameraPosition = await controller.getCameraPosition();
    final lookupToken = ++_addressLookupToken;
    final address = await widget.lookupAddress(cameraPosition.target.latitude, cameraPosition.target.longitude);
    if (!mounted || lookupToken != _addressLookupToken) return;
    setState(() {
      _selectedPosition = cameraPosition.target;
      _selectedAddress = address;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedPosition = _selectedPosition;
    final selectedAddress = _selectedAddress;
    return Stack(
      children: [
        Positioned.fill(
          child: NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: const NCameraPosition(
                target: LocationVerificationManualSelectionView.koreaCenterPosition,
                zoom: LocationVerificationManualSelectionView.koreaOverviewZoomLevel,
              ),
              logoAlign: NLogoAlign.leftBottom,
              logoMargin: NEdgeInsets.fromEdgeInsets(const EdgeInsets.only(left: 24, bottom: 180)),
              locationButtonEnable: false,
            ),
            onMapReady: (controller) {
              if (!_mapControllerCompleter.isCompleted) _mapControllerCompleter.complete(controller);
            },
            onCameraIdle: _onCameraIdle,
          ),
        ),

        // 서비스 지역 밖 안내
        Positioned(
          top: 16,
          left: 24.w,
          right: 24.w,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.opacity70Black, borderRadius: BorderRadius.circular(10.r)),
            child: Text(
              '서비스 지역(대한민국) 밖에서는 지도에서 동네를 직접 선택해요.',
              style: CustomTextStyles.p3.copyWith(color: AppColors.textColorWhite),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // 선택 위치 핀 (핀 끝이 화면 중앙)
        Center(
          child: Container(
            margin: EdgeInsets.only(bottom: 40.h),
            child: Shadex(
              shadowColor: AppColors.opacity20Black,
              shadowBlurRadius: 2.0,
              shadowOffset: const Offset(2, 2),
              child: SvgPicture.asset('assets/images/location-pin.svg'),
            ),
          ),
        ),

        // 선택 동네 + 인증 버튼 + 다시 확인
        Positioned(
          left: 24.w,
          right: 24.w,
          bottom: 24.h + MediaQuery.of(context).padding.bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedAddress != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.locationVerificationAreaLabel,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Text(selectedAddress.siDoSiGunGuEupMyoenDongText, style: CustomTextStyles.p2),
                ),
              CompletionButton(
                isEnabled: selectedAddress != null && selectedPosition != null,
                isLoading: widget.isSaving,
                buttonText: '이 동네로 인증하기',
                enabledOnPressed: () => widget.onVerifyPressed(selectedPosition!, selectedAddress!),
              ),
              LocationRecheckTextButton(isEnabled: !widget.isSaving, onPressed: widget.onRecheckPressed),
            ],
          ),
        ),
      ],
    );
  }
}
