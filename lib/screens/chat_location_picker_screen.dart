import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/utils/device_type.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/current_location_button.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:shadex/shadex.dart';

/// 채팅 위치 보내기 - 위치 선택 화면
/// 선택 완료 시 Navigator.pop(context, LocationAddress)로 반환
class ChatLocationPickerScreen extends StatefulWidget {
  const ChatLocationPickerScreen({super.key});

  @override
  State<ChatLocationPickerScreen> createState() => _ChatLocationPickerScreenState();
}

class _ChatLocationPickerScreenState extends State<ChatLocationPickerScreen> {
  final _locationService = LocationService();
  NLatLng? _currentPosition;
  NLatLng? _selectedPosition;
  LocationAddress? _selectedAddress;
  final Completer<NaverMapController> _mapControllerCompleter = Completer();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final hasPermission = await _locationService.requestPermission();
    if (!hasPermission) {
      const seoulCityHall = NLatLng(37.5665, 126.9780);
      setState(() => _currentPosition = seoulCityHall);
      await _updateAddress(seoulCityHall);
      return;
    }
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      final latLng = _locationService.positionToLatLng(position);
      setState(() => _currentPosition = latLng);
      await _updateAddress(latLng);
    } else {
      const seoulCityHall = NLatLng(37.5665, 126.9780);
      setState(() => _currentPosition = seoulCityHall);
      await _updateAddress(seoulCityHall);
    }
  }

  Future<void> _updateAddress(NLatLng position) async {
    final address = await _locationService.getAddressFromCoordinates(position);
    if (address != null && mounted) {
      setState(() {
        _selectedPosition = position;
        _selectedAddress = address;
      });
    }
  }

  Future<void> _onSend() async {
    if (_isSending || _selectedAddress == null || _selectedPosition == null) return;
    setState(() => _isSending = true);
    try {
      final result = LocationAddress(
        siDo: _selectedAddress!.siDo,
        siGunGu: _selectedAddress!.siGunGu,
        eupMyoenDong: _selectedAddress!.eupMyoenDong,
        ri: _selectedAddress!.ri,
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
      );
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: '위치 전송에 실패했습니다: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '위치 보내기'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                // 네이버 지도
                Positioned.fill(
                  child: _currentPosition == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
                      : NaverMap(
                          options: NaverMapViewOptions(
                            initialCameraPosition: NCameraPosition(target: _currentPosition!, zoom: 15),
                            logoAlign: NLogoAlign.leftBottom,
                            logoMargin: NEdgeInsets.fromEdgeInsets(EdgeInsets.only(left: 24.w, bottom: 137.h)),
                            indoorEnable: true,
                            locationButtonEnable: false,
                          ),
                          onMapReady: (controller) async {
                            if (!_mapControllerCompleter.isCompleted) {
                              _mapControllerCompleter.complete(controller);
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
                // 보내기 버튼
                Positioned(
                  left: 24.w,
                  right: 24.w,
                  bottom: 57.h,
                  child: CompletionButton(
                    isEnabled: _selectedAddress != null,
                    isLoading: _isSending,
                    buttonText: '보내기',
                    enabledOnPressed: _onSend,
                  ),
                ),
                // 현재 위치 버튼
                Positioned(
                  bottom: isTablet ? 200 : 160.h,
                  left: 24.w,
                  child: CurrentLocationButton(
                    onTap: () async {
                      final controller = await _mapControllerCompleter.future;
                      final position = await _locationService.getCurrentPosition();
                      if (position != null && mounted) {
                        final newPosition = _locationService.positionToLatLng(position);
                        await controller.updateCamera(
                          NCameraUpdate.fromCameraPosition(NCameraPosition(target: newPosition, zoom: 15)),
                        );
                        controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);
                        setState(() => _currentPosition = newPosition);
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
