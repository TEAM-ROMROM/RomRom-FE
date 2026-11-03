import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/current_location_button.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/onboarding_title_header.dart';
import 'package:shadex/shadex.dart';

class ItemRegisterLocationScreen extends StatefulWidget {
  final void Function(LocationAddress)? onLocationSelected;
  final VoidCallback? onClose;
  final LocationAddress? initialLocation; // 이전에 선택한 위치
  const ItemRegisterLocationScreen({super.key, this.onLocationSelected, this.onClose, this.initialLocation});

  @override
  State<ItemRegisterLocationScreen> createState() => _ItemRegisterLocationScreenState();
}

class _ItemRegisterLocationScreenState extends State<ItemRegisterLocationScreen> {
  final _locationService = LocationService();
  NLatLng? _currentPosition;
  NLatLng? _selectedPosition; // 핀이 가리키는 선택된 위치
  LocationAddress? _selectedAddress;
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  bool _isLoading = false; // 로딩 상태 관리
  // 현재 위치 버튼 처리 중 여부 (연타 시 위치 조회 중복 방지)
  bool _isMovingToCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    // 이전에 선택한 위치가 있다면 그 위치로 초기화
    if (widget.initialLocation != null &&
        widget.initialLocation!.latitude != null &&
        widget.initialLocation!.longitude != null) {
      final initialPosition = NLatLng(widget.initialLocation!.latitude!, widget.initialLocation!.longitude!);
      setState(() {
        _currentPosition = initialPosition;
        _selectedPosition = initialPosition;
        _selectedAddress = widget.initialLocation;
      });
      return;
    }

    final hasPermission = await _locationService.requestPermission();
    if (!hasPermission) {
      await _showFallbackPosition(reason: '위치 권한이 없어');
      return;
    }
    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;
    if (position == null) {
      await _showFallbackPosition(reason: '현재 위치를 찾지 못해');
      return;
    }
    setState(() {
      _currentPosition = _locationService.positionToLatLng(position);
    });
    await _updateAddress(_currentPosition!);
  }

  /// 위치 권한 거부·조회 실패: 기본 위치(서울시청)로 지도 표시 > 직접 옮기라는 안내
  Future<void> _showFallbackPosition({required String reason}) async {
    if (!mounted) return;
    setState(() {
      _currentPosition = LocationService.fallbackPosition;
    });
    CommonSnackBar.show(
      context: context,
      message: '$reason 기본 위치로 표시했어요. 지도를 움직여 교환 위치를 골라 주세요.',
      type: SnackBarType.info,
    );
    await _updateAddress(LocationService.fallbackPosition);
  }

  /// 현재 위치 버튼: 중복 탭 차단 > 권한·위치 조회 > 지도 이동·주소 갱신, 실패 시 안내
  Future<void> _onCurrentLocationButtonPressed() async {
    // 지도 준비 전 탭 무시 (컨트롤러 대기 중 잠김 방지)
    if (_isMovingToCurrentLocation || !_mapControllerCompleter.isCompleted) return;
    _isMovingToCurrentLocation = true;
    try {
      final hasPermission = await _locationService.requestPermission();
      final position = hasPermission ? await _locationService.getCurrentPosition() : null;
      if (!mounted) return;
      if (position == null) {
        CommonSnackBar.show(
          context: context,
          message: hasPermission ? '현재 위치를 찾지 못했어요. 잠시 후 다시 시도해 주세요.' : '현재 위치를 쓰려면 설정에서 위치 권한을 허용해 주세요.',
          type: SnackBarType.error,
        );
        return;
      }

      final controller = await _mapControllerCompleter.future;
      final newPosition = _locationService.positionToLatLng(position);
      // 지도를 현재 위치로 이동 + 현재 위치 점 표시
      await controller.updateCamera(NCameraUpdate.fromCameraPosition(NCameraPosition(target: newPosition, zoom: 15)));
      controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);
      if (!mounted) return;
      setState(() {
        _currentPosition = newPosition;
      });
      await _updateAddress(newPosition);
    } finally {
      // (성공·실패 공통)
      _isMovingToCurrentLocation = false;
    }
  }

  Future<void> _updateAddress(NLatLng position) async {
    final address = await _locationService.getAddressFromCoordinates(position);
    if (!mounted) return;
    // 해외 좌표 등으로 주소를 받지 못한 경우 _selectedAddress=null 로 리셋해
    // 직전 국내 주소가 남아 잘못된 위치가 등록되는 stale state 버그를 막는다.
    setState(() {
      _selectedPosition = position;
      _selectedAddress = address;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '', onBackPressed: widget.onClose),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingTitleHeader(title: '교환 희망 위치', subtitle: '공개된 공간을 선택하면 안전하게 교환할 수 있어요'),
          Expanded(
            child: Stack(
              children: [
                // 네이버 지도 전체 채우기
                Positioned.fill(
                  child: _currentPosition == null
                      ? const Center(child: CommonLoadingIndicator())
                      : NaverMap(
                          options: NaverMapViewOptions(
                            initialCameraPosition: NCameraPosition(target: _currentPosition!, zoom: 15),
                            logoAlign: NLogoAlign.leftBottom,
                            logoMargin: NEdgeInsets.fromEdgeInsets(EdgeInsets.only(left: 24.w, bottom: 137.h)),
                            indoorEnable: true,
                            locationButtonEnable: false, // 기본 위치 버튼 비활성화하고 커스텀 버튼 사용
                          ),
                          onMapReady: (controller) async {
                            if (!_mapControllerCompleter.isCompleted) {
                              _mapControllerCompleter.complete(controller);
                              // 현재 위치 추적 활성화 (파란색 점 표시)
                              controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);
                            }
                          },
                          onCameraIdle: () async {
                            final controller = await _mapControllerCompleter.future;
                            final position = await controller.getCameraPosition();
                            await _updateAddress(position.target);
                          },
                        ),
                ),
                // 중앙 핀 표시
                Center(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 40.h), // 핀의 끝부분이 정확한 위치를 가리키도록 조정
                    child: Shadex(
                      shadowColor: AppColors.opacity20Black,
                      shadowBlurRadius: 2.0,
                      shadowOffset: const Offset(2, 2),
                      child: SvgPicture.asset('assets/images/location-pin.svg'),
                    ),
                  ),
                ),
                // 해외 좌표 안내 (주소 못 받은 경우 표시)
                if (_currentPosition != null && _selectedAddress == null)
                  Positioned(
                    left: 24.w,
                    right: 24.w,
                    bottom: 110.h,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.opacity80Black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '국내 위치만 등록할 수 있어요',
                        textAlign: TextAlign.center,
                        style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite),
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
                      isLoading: _isLoading,
                      buttonText: '선택 완료',
                      enabledOnPressed: () async {
                        try {
                          setState(() {
                            _isLoading = true; // 로딩 시작
                          });
                          // 선택된 위치의 정확한 좌표로 LocationAddress 업데이트
                          if (_selectedAddress != null && _selectedPosition != null) {
                            final updatedAddress = LocationAddress(
                              siDo: _selectedAddress!.siDo,
                              siGunGu: _selectedAddress!.siGunGu,
                              eupMyoenDong: _selectedAddress!.eupMyoenDong,
                              ri: _selectedAddress!.ri,
                              latitude: _selectedPosition!.latitude,
                              longitude: _selectedPosition!.longitude,
                            );
                            widget.onLocationSelected?.call(updatedAddress);
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            CommonSnackBar.show(
                              context: context,
                              message: ErrorUtils.getErrorMessage(e),
                              type: SnackBarType.error,
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false; // 로딩 종료
                            });
                          }
                        }
                      },
                    ),
                  ),
                ),
                // 커스텀 위치 버튼
                Positioned(
                  bottom: 160.h,
                  left: 24.w,
                  child: CurrentLocationButton(onTap: _onCurrentLocationButtonPressed, iconSize: 24.h),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
