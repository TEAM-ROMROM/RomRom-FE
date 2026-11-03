import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/refresh_trigger.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/home_feed_provider.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/screens/my_page/my_location_verification_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/utils/latest_value_save_queue.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/current_location_button.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common/range_slider_widget.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

/// 탐색 범위 설정 화면
/// 네이버 지도와 커스텀 범위 슬라이더를 통해 탐색 범위를 설정합니다.
class SearchRangeSettingScreen extends ConsumerStatefulWidget {
  /// 범위 변경 완료 시 호출되는 콜백
  final ValueChanged<int>? onRangeChanged;

  const SearchRangeSettingScreen({super.key, this.onRangeChanged});

  @override
  ConsumerState<SearchRangeSettingScreen> createState() => _SearchRangeSettingScreenState();
}

class _SearchRangeSettingScreenState extends ConsumerState<SearchRangeSettingScreen> {
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  NLatLng? _currentPosition;
  int _selectedRangeIndex = 0;
  // 서버에 마지막으로 저장된 범위 index (저장 실패 시 화면 값 복원 기준)
  int _savedRangeIndex = 0;
  // 범위 저장 직렬화 (슬라이더 연속 변경 시 진행 중 저장 뒤 마지막 값만 저장)
  late final LatestValueSaveQueue<int> _rangeSaveQueue = LatestValueSaveQueue<int>(
    saveValue: (rangeIndex) => ref
        .read(memberProfileProvider.notifier)
        .saveSearchRadius(defaultSearchRangeOptions[rangeIndex].distanceKm * 1000),
  );
  NCircleOverlay? _rangeCircle;
  bool _locationNotSet = false;
  // 위치·범위 조회 실패 (위치 미설정 안내와 구분 > 다시 시도)
  bool _hasLoadError = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// 서버에서 위치 및 탐색 범위 로드: 위치 없음 > 위치 설정 안내, 조회 실패 > 다시 시도
  Future<void> _initializeData() async {
    if (_hasLoadError) setState(() => _hasLoadError = false);
    try {
      final memberProfile = await ref.read(memberProfileProvider.notifier).fetchLatest();
      final location = memberProfile.location;
      final searchRadiusInMeters = memberProfile.member?.searchRadiusInMeters ?? 7500.0;

      if (!mounted) return;

      if (location?.latitude == null || location?.longitude == null) {
        setState(() => _locationNotSet = true);
        return;
      }

      setState(() {
        _currentPosition = NLatLng(location!.latitude!, location.longitude!);
        _selectedRangeIndex = searchRangeIndexForRadius(searchRadiusInMeters);
        _savedRangeIndex = _selectedRangeIndex;
      });
    } catch (e) {
      debugPrint('위치/탐색 범위 조회 실패: $e');
      if (mounted) setState(() => _hasLoadError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: const CommonAppBar(title: '탐색 범위 설정', showBottomBorder: true),
      body: _hasLoadError
          ? EmptyStateView.error(centerText: '탐색 범위를 불러오지 못했어요', onRetry: _initializeData)
          : _locationNotSet
          ? _buildLocationNotSetView()
          : _currentPosition == null
          ? const Center(child: CommonLoadingIndicator())
          : Column(
              children: [
                Expanded(child: _buildMapSection()),
                _buildSliderSection(),
              ],
            ),
    );
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
            _updateRangeCircle();
          },
        ),
        // 내 위치로 이동 버튼
        Positioned(
          bottom: 48.h,
          left: 24.w,
          child: CurrentLocationButton(
            onTap: () async {
              final controller = await _mapControllerCompleter.future;
              await controller.updateCamera(NCameraUpdate.withParams(target: _currentPosition));
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

  /// 위치 미설정 시 안내 UI
  Widget _buildLocationNotSetView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 64.sp, color: AppColors.opacity60White),
            SizedBox(height: 24.h),
            Text(
              '내 위치를 먼저 설정해주세요',
              style: CustomTextStyles.h3.copyWith(color: AppColors.textColorWhite),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              '탐색 범위를 설정하려면 먼저 내 위치인증이 필요합니다.',
              style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                onPressed: () async {
                  await context.navigateTo(screen: const MyLocationVerificationScreen());
                  // 위치인증 후 돌아오면 데이터 재로드
                  if (mounted) {
                    setState(() {
                      _locationNotSet = false;
                      _currentPosition = null;
                    });
                    _initializeData();
                  }
                },
                child: Text(
                  '위치 설정하러 가기',
                  style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryBlack),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 범위 변경 처리: 화면 즉시 반영 > 저장
  void _onRangeChanged(int index) {
    setState(() => _selectedRangeIndex = index);
    _updateRangeCircle();
    _updateCameraZoom();
    _saveSearchRadius(index);
  }

  /// 탐색 범위 저장 (직렬): 성공 값은 항상 저장 기준에 반영 > 홈 피드 새로고침, 마지막 시도 실패 시 마지막 저장 값으로 복원 + 안내
  Future<void> _saveSearchRadius(int index) async {
    final saveResult = await _rangeSaveQueue.save(index);
    // 진행 중 저장 뒤로 합쳐진 요청 > 결과는 앞선 호출이 처리
    if (saveResult == null || !mounted) return;

    final lastSavedRangeIndex = saveResult.lastSavedValue;
    if (lastSavedRangeIndex != null) {
      _savedRangeIndex = lastSavedRangeIndex;
      widget.onRangeChanged?.call(lastSavedRangeIndex);
      // 조회 조건 변경 > 홈 피드 즉시 갱신 (30초 제한 우회)
      ref.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.searchRangeChanged);
    }
    if (!saveResult.isLatestSaveFailed) return;

    final saveError = saveResult.latestSaveError;
    debugPrint('탐색 범위 저장 실패: $saveError');
    setState(() => _selectedRangeIndex = _savedRangeIndex);
    _updateRangeCircle();
    _updateCameraZoom();
    CommonSnackBar.show(
      context: context,
      message: saveError != null ? ErrorUtils.getErrorMessage(saveError) : '탐색 범위를 저장하지 못했어요. 잠시 후 다시 시도해 주세요.',
      type: SnackBarType.error,
    );
  }

  /// 범위 원 업데이트
  Future<void> _updateRangeCircle() async {
    if (!_mapControllerCompleter.isCompleted || _currentPosition == null) return;

    final controller = await _mapControllerCompleter.future;
    final radiusMeters = defaultSearchRangeOptions[_selectedRangeIndex].distanceKm * 1000;

    if (_rangeCircle != null) {
      await controller.deleteOverlay(_rangeCircle!.info);
    }

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
    if (!_mapControllerCompleter.isCompleted || _currentPosition == null) return;

    final controller = await _mapControllerCompleter.future;
    await controller.updateCamera(
      NCameraUpdate.withParams(target: _currentPosition, zoom: _getZoomLevel(_selectedRangeIndex)),
    );
  }

  /// 범위에 따른 줌 레벨 반환
  double _getZoomLevel(int rangeIndex) {
    switch (rangeIndex) {
      case 0:
        return 12.0;
      case 1:
        return 11.0;
      case 2:
        return 10.5;
      case 3:
        return 10.0;
      default:
        return 12.0;
    }
  }
}
