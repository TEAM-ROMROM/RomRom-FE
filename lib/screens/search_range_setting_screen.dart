import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/current_location_button.dart';
import 'package:romrom_fe/widgets/common/range_slider_widget.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

/// 탐색 범위 설정 화면
/// 네이버 지도와 커스텀 범위 슬라이더를 통해 탐색 범위를 설정합니다.
class SearchRangeSettingScreen extends StatefulWidget {
  /// 범위 변경 완료 시 호출되는 콜백
  final ValueChanged<int>? onRangeChanged;

  const SearchRangeSettingScreen({super.key, this.onRangeChanged});

  @override
  State<SearchRangeSettingScreen> createState() => _SearchRangeSettingScreenState();
}

class _SearchRangeSettingScreenState extends State<SearchRangeSettingScreen> {
  final _locationService = LocationService();
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  NLatLng? _currentPosition;
  int _selectedRangeIndex = 0;
  NCircleOverlay? _rangeCircle;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: _buildAppBar(),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 지도 영역
                Expanded(child: _buildMapSection()),
                // 슬라이더 영역
                _buildSliderSection(),
              ],
            ),
    );
  }

  /// 앱바 빌드
  PreferredSizeWidget _buildAppBar() {
    return const CommonAppBar(title: '탐색 범위 설정', showBottomBorder: true);
  }

  /// 지도 섹션 빌드
  Widget _buildMapSection() {
    return Stack(
      children: [
        NaverMap(
          options: NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(target: _currentPosition!, zoom: _getZoomLevel(_selectedRangeIndex)),
            logoAlign: NLogoAlign.leftBottom,
            logoMargin: NEdgeInsets.fromEdgeInsets(EdgeInsets.only(left: 24.w, bottom: 20.h)),
            indoorEnable: true,
            locationButtonEnable: false,
            consumeSymbolTapEvents: false,
          ),
          forceGesture: false,
          onMapReady: (controller) async {
            if (!_mapControllerCompleter.isCompleted) {
              _mapControllerCompleter.complete(controller);
            }
            await controller.setLocationTrackingMode(NLocationTrackingMode.follow);
            _updateRangeCircle();
          },
        ),
        // 현재 위치 버튼
        Positioned(
          bottom: 48.h,
          left: 24.w,
          child: CurrentLocationButton(
            onTap: () async {
              final controller = await _mapControllerCompleter.future;
              await controller.setLocationTrackingMode(NLocationTrackingMode.follow);
            },
            iconSize: 24.h,
          ),
        ),
      ],
    );
  }

  /// 슬라이더 섹션 빌드
  Widget _buildSliderSection() {
    return Container(
      padding: EdgeInsets.fromLTRB(45.w, 45.h, 45.w, 70.h),
      decoration: const BoxDecoration(color: AppColors.primaryBlack),
      child: RangeSliderWidget(
        selectedIndex: _selectedRangeIndex,
        options: defaultSearchRangeOptions,
        onChanged: _onRangeChanged,
      ),
    );
  }

  /// 위치 초기화
  Future<void> _initializeLocation() async {
    try {
      // 위치 서비스 활성화
      final hasPermission = await _locationService.requestPermission();
      if (!hasPermission) return;

      // 현재 위치 가져오기
      final position = await _locationService.getCurrentPosition();

      final memberApi = MemberApi();
      final memberResponse = await memberApi.getMemberInfo();

      if (mounted) {
        // 기존에 저장된 탐색 범위로 초기화
        double searchRadiusInMeters = memberResponse.member?.searchRadiusInMeters ?? 7500.0;

        if (position != null) {
          setState(() {
            _currentPosition = _locationService.positionToLatLng(position);
            _selectedRangeIndex = _getRangeIndex(searchRadiusInMeters);
          });
        }
      }
    } catch (e) {
      debugPrint('위치 초기화 실패: $e');
    }
  }

  /// 범위 변경 처리
  void _onRangeChanged(int index) {
    setState(() {
      _selectedRangeIndex = index;
    });
    _updateRangeCircle();
    _updateCameraZoom();
    _saveSearchRadius(index);
    widget.onRangeChanged?.call(index);
  }

  /// 탐색 범위 저장
  Future<void> _saveSearchRadius(int index) async {
    try {
      final radiusInMeters = defaultSearchRangeOptions[index].distanceKm * 1000;
      final isSuccess = await MemberApi().saveSearchRadius(radiusInMeters);

      if (mounted && isSuccess) {
        CommonSnackBar.show(context: context, message: '탐색 범위가 저장되었습니다', type: SnackBarType.success);
      }
    } catch (e) {
      debugPrint('탐색 범위 저장 실패: $e');
      if (mounted) {
        CommonSnackBar.show(context: context, message: '탐색 범위 저장에 실패했습니다', type: SnackBarType.error);
      }
    }
  }

  /// 범위 원 업데이트
  Future<void> _updateRangeCircle() async {
    if (!_mapControllerCompleter.isCompleted || _currentPosition == null) {
      return;
    }

    final controller = await _mapControllerCompleter.future;
    final radiusMeters = defaultSearchRangeOptions[_selectedRangeIndex].distanceKm * 1000;

    // 기존 원 제거
    if (_rangeCircle != null) {
      await controller.deleteOverlay(_rangeCircle!.info);
    }

    // 새 원 추가
    _rangeCircle = NCircleOverlay(
      id: 'range_circle',
      center: _currentPosition!,
      radius: radiusMeters,
      color: AppColors.primaryYellow.withValues(alpha: 0.15),
      outlineColor: AppColors.primaryYellow.withValues(alpha: 0.5),
      outlineWidth: 2,
    );

    await controller.addOverlay(_rangeCircle!);
  }

  /// 카메라 줌 업데이트
  Future<void> _updateCameraZoom() async {
    if (!_mapControllerCompleter.isCompleted || _currentPosition == null) {
      return;
    }

    final controller = await _mapControllerCompleter.future;
    final zoom = _getZoomLevel(_selectedRangeIndex);

    await controller.updateCamera(NCameraUpdate.withParams(target: _currentPosition, zoom: zoom));
  }

  /// 범위에 따른 줌 레벨 반환
  double _getZoomLevel(int rangeIndex) {
    // 범위가 클수록 줌 아웃
    switch (rangeIndex) {
      case 0: // 2.5km
        return 12.0;
      case 1: // 5km
        return 11.0;
      case 2: // 7.5km
        return 10.5;
      case 3: // 10km
        return 10.0;
      default:
        return 12.0;
    }
  }

  /// 범위에 따른 줌 레벨 반환
  int _getRangeIndex(double searchRadiusInMeters) {
    // 범위가 클수록 줌 아웃
    // 미터 단위로 비교하여 부동소수점 오차 방지
    final radiusInMeters = searchRadiusInMeters.round();
    if (radiusInMeters <= 2500) return 0;
    if (radiusInMeters <= 5000) return 1;
    if (radiusInMeters <= 7500) return 2;
    if (radiusInMeters <= 10000) return 3;
    return 0;
  }
}
