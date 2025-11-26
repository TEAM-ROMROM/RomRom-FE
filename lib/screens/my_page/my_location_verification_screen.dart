import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/current_location_button.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

class MyLocationVerificationScreen extends StatefulWidget {
  const MyLocationVerificationScreen({super.key});

  @override
  State<MyLocationVerificationScreen> createState() =>
      _MyLocationVerificationScreenState();
}

class _MyLocationVerificationScreenState
    extends State<MyLocationVerificationScreen> {
  final _locationService = LocationService();
  NLatLng? _currentPosition;
  NLatLng? _selectedPosition;
  LocationAddress? _selectedAddress;
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
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
        _selectedPosition = position;
        _selectedAddress = address;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 타이틀
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                Text(
                  '내 위치 인증',
                  style: CustomTextStyles.h1,
                ),
                SizedBox(height: 16.h),
              ],
            ),
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
                              EdgeInsets.only(left: 24.w, bottom: 220.h),
                            ),
                            indoorEnable: true,
                            locationButtonEnable: false,
                          ),
                          onMapReady: (controller) async {
                            if (!_mapControllerCompleter.isCompleted) {
                              _mapControllerCompleter.complete(controller);
                              await controller.setLocationTrackingMode(
                                  NLocationTrackingMode.noFollow);
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
                    margin: EdgeInsets.only(bottom: 40.h),
                    child: SvgPicture.asset(
                      'assets/images/location-pin.svg',
                    ),
                  ),
                ),
                // 주소 표시 박스
                Positioned(
                  left: 24.w,
                  right: 24.w,
                  bottom: 140.h,
                  child: Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBlack1,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: _selectedAddress != null
                        ? Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16.sp,
                                color: AppColors.primaryYellow,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  '${_selectedAddress!.siGunGu} ${_selectedAddress!.eupMyoenDong}'.trim(),
                                  style: CustomTextStyles.p2.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Text(
                              '위치 정보를 가져오는 중...',
                              style: CustomTextStyles.p2.copyWith(
                                fontWeight: FontWeight.w400,
                                color: AppColors.opacity60White,
                              ),
                            ),
                          ),
                  ),
                ),
                // 인증 완료 버튼
                Positioned(
                  left: 24.w,
                  right: 24.w,
                  bottom: 57.h,
                  child: SizedBox(
                    width: double.infinity,
                    child: IgnorePointer(
                      ignoring: _isLoading,
                      child: CompletionButton(
                        isEnabled: _selectedAddress != null,
                        buttonText: '인증 완료',
                        enabledOnPressed: () async {
                          try {
                            setState(() {
                              _isLoading = true;
                            });

                            if (_selectedAddress != null &&
                                _selectedPosition != null) {
                              // TODO: MemberApi().saveMemberLocation() 호출
                              // final locationData = LocationAddress(
                              //   siDo: _selectedAddress!.siDo,
                              //   siGunGu: _selectedAddress!.siGunGu,
                              //   eupMyoenDong: _selectedAddress!.eupMyoenDong,
                              //   ri: _selectedAddress!.ri,
                              //   latitude: _selectedPosition!.latitude,
                              //   longitude: _selectedPosition!.longitude,
                              // );
                              // final memberApi = MemberApi();
                              // await memberApi.saveMemberLocation(locationData);

                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                                Navigator.pop(context);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              CommonSnackBar.show(
                                context: context,
                                message: '위치 인증에 실패했습니다: $e',
                                type: SnackBarType.error,
                              );
                            }
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),
                // 커스텀 위치 버튼
                Positioned(
                  bottom: 243.h,
                  left: 24.w,
                  child: CurrentLocationButton(
                    onTap: () async {
                      final controller = await _mapControllerCompleter.future;

                      final position =
                          await _locationService.getCurrentPosition();
                      if (position != null) {
                        final newPosition =
                            _locationService.positionToLatLng(position);

                        await controller.updateCamera(
                          NCameraUpdate.fromCameraPosition(
                            NCameraPosition(
                              target: newPosition,
                              zoom: 15,
                            ),
                          ),
                        );

                        await controller.setLocationTrackingMode(
                            NLocationTrackingMode.noFollow);

                        setState(() {
                          _currentPosition = newPosition;
                        });

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
