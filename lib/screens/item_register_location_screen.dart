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
  final LocationAddress? initialLocation; // 이전에 선택한 위치
  const ItemRegisterLocationScreen({
    super.key, 
    this.onLocationSelected, 
    this.onClose,
    this.initialLocation,
  });

  @override
  State<ItemRegisterLocationScreen> createState() =>
      _ItemRegisterLocationScreenState();
}

class _ItemRegisterLocationScreenState
    extends State<ItemRegisterLocationScreen> {
  final _locationService = LocationService();
  NLatLng? _currentPosition;
  NLatLng? _selectedPosition; // 핀이 가리키는 선택된 위치
  LocationAddress? _selectedAddress;
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

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
      final initialPosition = NLatLng(
        widget.initialLocation!.latitude!,
        widget.initialLocation!.longitude!,
      );
      setState(() {
        _currentPosition = initialPosition;
        _selectedPosition = initialPosition;
        _selectedAddress = widget.initialLocation;
      });
      return;
    }
    
    final hasPermission = await _locationService.requestPermission();
    if (!hasPermission) {
      // FIXME : 디버깅용: 위치 권한 없을 때 서울 시청 좌표로 세팅
      const seoulCityHall = NLatLng(37.5665, 126.9780);
      setState(() {
        _currentPosition = seoulCityHall;
      });
      await _updateAddress(seoulCityHall);
      return;
    }
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentPosition = _locationService.positionToLatLng(position);
      });
      await _updateAddress(_currentPosition!);
    } else {
      //FIXME : 디버깅용: 위치 못 받아올 때 서울 시청 좌표로 세팅
      const seoulCityHall = NLatLng(37.5665, 126.9780);
      setState(() {
        _currentPosition = seoulCityHall;
      });
      await _updateAddress(seoulCityHall);
    }
  }

  Future<void> _updateAddress(NLatLng position) async {
    final address = await _locationService.getAddressFromCoordinates(position);
    if (address != null) {
      setState(() {
        _selectedPosition = position; // 핀이 가리키는 위치 저장
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
                            locationButtonEnable: false, // 기본 위치 버튼 비활성화하고 커스텀 버튼 사용
                          ),
                          onMapReady: (controller) async {
                            if (!_mapControllerCompleter.isCompleted) {
                              _mapControllerCompleter.complete(controller);
                              
                              // 현재 위치 추적 활성화 (파란색 점 표시)
                              await controller.setLocationTrackingMode(
                                NLocationTrackingMode.noFollow
                              );
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
                // 중앙 핀 표시
                Center(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 40.h), // 핀의 끝부분이 정확한 위치를 가리키도록 조정
                    child: Icon(
                      Icons.location_pin,
                      size: 40.sp,
                      color: AppColors.primaryYellow,
                    ),
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
                      enabledOnPressed: () {
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
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ),
                // 커스텀 위치 버튼 
                Positioned(
                  bottom: 160.h,
                  left: 24.w,
                  child: CurrentLocationButton(
                    onTap: () async {
                      final controller = await _mapControllerCompleter.future;
                      
                      // 현재 위치 다시 가져오기
                      final position = await _locationService.getCurrentPosition();
                      if (position != null) {
                        final newPosition = _locationService.positionToLatLng(position);
                        
                        // 지도를 현재 위치로 이동
                        await controller.updateCamera(
                          NCameraUpdate.fromCameraPosition(
                            NCameraPosition(
                              target: newPosition,
                              zoom: 15,
                            ),
                          ),
                        );
                        
                        // 현재 위치 추적 활성화 (파란색 점 표시)
                        await controller.setLocationTrackingMode(
                          NLocationTrackingMode.noFollow
                        );
                        
                        // 현재 위치 업데이트
                        setState(() {
                          _currentPosition = newPosition;
                        });
                        
                        // 주소 정보 업데이트
                        await _updateAddress(newPosition);
                      }
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
