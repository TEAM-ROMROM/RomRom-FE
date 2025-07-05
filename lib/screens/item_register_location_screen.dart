import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/current_location_button.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/onboarding_title_header.dart';

class ItemRegisterLocationScreen extends StatefulWidget {
  final void Function(LocationAddress)? onLocationSelected;
  final VoidCallback? onClose;
  const ItemRegisterLocationScreen(
      {super.key, this.onLocationSelected, this.onClose});

  @override
  State<ItemRegisterLocationScreen> createState() =>
      _ItemRegisterLocationScreenState();
}

class _ItemRegisterLocationScreenState
    extends State<ItemRegisterLocationScreen> {
  final _locationService = LocationService();
  NLatLng? _currentPosition;
  LocationAddress? _selectedAddress;
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final hasPermission = await _locationService.requestPermission();
    if (!hasPermission) return;
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentPosition = _locationService.positionToLatLng(position);
      });
      await _updateAddress(_currentPosition!);
    }
  }

  Future<void> _updateAddress(NLatLng position) async {
    final address = await _locationService.getAddressFromCoordinates(position);
    if (address != null) {
      setState(() {
        _selectedAddress = address;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '',
        onBackPressed: widget.onClose,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingTitleHeader(
            title: '거래 희망 위치',
            subtitle: '공개된 공간을 선택하면 안전하게 거래할 수 있어요',
          ),
          Expanded(
            child: Stack(
              children: [
                // 네이버 지도 전체 채우기
                Positioned.fill(
                  child: _currentPosition == null
                      ? const Center(child: CircularProgressIndicator())
                      : NaverMap(
                          options: NaverMapViewOptions(
                            initialCameraPosition: NCameraPosition(
                              target: _currentPosition!,
                              zoom: 15,
                            ),
                            logoAlign: NLogoAlign.leftBottom,
                            logoMargin: NEdgeInsets.fromEdgeInsets(
                              EdgeInsets.only(left: 24.w, bottom: 137.h),
                            ),
                            indoorEnable: true,
                            locationButtonEnable: false,
                          ),
                          onMapReady: (controller) async {
                            if (!_mapControllerCompleter.isCompleted) {
                              _mapControllerCompleter.complete(controller);
                            }
                          },
                          onCameraIdle: () async {
                            final controller =
                                await _mapControllerCompleter.future;
                            final position =
                                await controller.getCameraPosition();
                            await _updateAddress(position.target);
                          },
                        ),
                ),
                // 주소 정보 표시 (상단)
                if (_selectedAddress != null)
                  Positioned(
                    top: kToolbarHeight + 24.h,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.locationVerificationAreaLabel,
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        child: Text(
                          '${_selectedAddress!.siDo} ${_selectedAddress!.siGunGu} ${_selectedAddress!.eupMyoenDong}',
                          style: CustomTextStyles.p2,
                        ),
                      ),
                    ),
                  ),
                // 선택 완료 버튼 (하단 고정, 지도 위에 겹치게)
                Positioned(
                  left: 24.w,
                  right: 24.w,
                  bottom: 57.h,
                  child: SizedBox(
                    width: double.infinity,
                    child: CompletionButton(
                      isEnabled: _selectedAddress != null,
                      buttonText: '선택 완료',
                      buttonType: 2,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 165.h,
                  left: 24.w,
                  child: CurrentLocationButton(
                    onTap: () async {
                      final controller = await _mapControllerCompleter.future;
                      await controller.setLocationTrackingMode(
                          NLocationTrackingMode.follow);
                    },
                    iconSize: 24.h,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
