import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/current_location_button.dart';
import 'package:shadex/shadex.dart';

class LocationVerificationStep extends StatefulWidget {
  final VoidCallback onNext;

  const LocationVerificationStep({super.key, required this.onNext});

  @override
  State<LocationVerificationStep> createState() => _LocationVerificationStepState();
}

class _LocationVerificationStepState extends State<LocationVerificationStep> {
  final _locationService = LocationService();
  NLatLng? _currentPosition;
  LocationAddress? _selectedAddress;
  NLatLng? _selectedPosition;
  bool _isVerifying = false;
  bool _hasLocationPermission = false;
  int _addressUpdateToken = 0;
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  // 대한민국 중심 좌표 (전국이 보이는 줌 레벨용)
  static const NLatLng _koreaCenter = NLatLng(36.5, 127.5);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final hasPermission = await _locationService.requestPermission();
    if (!hasPermission) {
      // 권한 없음 → 전국 지도에서 핀으로 선택
      if (mounted) setState(() => _hasLocationPermission = false);
      return;
    }
    if (mounted) setState(() => _hasLocationPermission = true);

    final position = await _locationService.getCurrentPosition();
    if (mounted && position != null) {
      final latLng = _locationService.positionToLatLng(position);
      setState(() {
        _currentPosition = latLng;
      });
      // 지도 컨트롤러가 준비됐으면 현재 위치로 카메라 이동
      _mapControllerCompleter.future.then((controller) {
        if (!mounted) return;
        controller.updateCamera(NCameraUpdate.fromCameraPosition(NCameraPosition(target: latLng, zoom: 15)));
        controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);
      });
      await _updateAddress(latLng);
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateAddress(NLatLng position) async {
    final token = ++_addressUpdateToken;
    final address = await _locationService.getAddressFromCoordinates(position);
    if (mounted && address != null && token == _addressUpdateToken) {
      setState(() {
        _selectedPosition = position;
        _selectedAddress = address;
      });
    }
  }

  Future<void> _onVerifyLocationPressed() async {
    if (_isVerifying || _selectedAddress == null || _selectedPosition == null) return;
    setState(() => _isVerifying = true);
    try {
      await MemberApi().saveMemberLocation(
        longitude: _selectedPosition!.longitude,
        latitude: _selectedPosition!.latitude,
        siDo: _selectedAddress!.siDo,
        siGunGu: _selectedAddress!.siGunGu,
        eupMyoenDong: _selectedAddress!.eupMyoenDong,
        ri: _selectedAddress!.ri,
      );
      widget.onNext();
    } catch (e) {
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: '위치 저장에 실패했습니다: $e', type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = _currentPosition ?? _koreaCenter;
    final initialZoom = _currentPosition != null ? 15.0 : 6.5;

    return Stack(
      children: [
        // 지도 전체 채우기
        Positioned.fill(
          child: NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(target: initialTarget, zoom: initialZoom),
              logoAlign: NLogoAlign.leftBottom,
              logoMargin: NEdgeInsets.fromEdgeInsets(const EdgeInsets.only(left: 24, bottom: 137)),
              indoorEnable: true,
              locationButtonEnable: false,
            ),
            onMapReady: (controller) {
              if (!_mapControllerCompleter.isCompleted) {
                _mapControllerCompleter.complete(controller);
                if (_currentPosition != null) {
                  controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);
                }
              }
            },
            onCameraIdle: () async {
              final controller = await _mapControllerCompleter.future;
              final cameraPos = await controller.getCameraPosition();
              await _updateAddress(cameraPos.target);
            },
          ),
        ),

        // 중앙 핀
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

        // 현재 위치 버튼 (권한 있을 때만 표시)
        if (_hasLocationPermission)
          Positioned(
            bottom: 160.h,
            left: 24.w,
            child: CurrentLocationButton(
              onTap: () async {
                final controller = await _mapControllerCompleter.future;
                final position = await _locationService.getCurrentPosition();
                if (position != null) {
                  final newPos = _locationService.positionToLatLng(position);
                  await controller.updateCamera(
                    NCameraUpdate.fromCameraPosition(NCameraPosition(target: newPos, zoom: 15)),
                  );
                  controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);
                  if (mounted) setState(() => _currentPosition = newPos);
                  await _updateAddress(newPos);
                }
              },
              iconSize: 24.h,
            ),
          ),

        // 하단 주소 + 버튼 영역
        Positioned(
          left: 24.w,
          right: 24.w,
          bottom: 57.h,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedAddress != null)
                Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.locationVerificationAreaLabel,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Text(
                    '${_selectedAddress!.siDo} ${_selectedAddress!.siGunGu} ${_selectedAddress!.eupMyoenDong}',
                    style: CustomTextStyles.p2,
                  ),
                ),
              CompletionButton(
                isEnabled: _selectedAddress != null,
                isLoading: _isVerifying,
                buttonText: '이 위치로 등록하기',
                enabledOnPressed: _onVerifyLocationPressed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
