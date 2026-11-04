import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/gps_location_check_result.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/providers/location_verification_provider.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/location_verification/location_verification_explanation_modal.dart';
import 'package:romrom_fe/widgets/location_verification/location_verification_failure_view.dart';
import 'package:romrom_fe/widgets/location_verification/location_verification_manual_selection_view.dart';
import 'package:romrom_fe/widgets/location_verification/location_verification_map_view.dart';

/// 동네 인증 화면: (권한 미결정 + 안내 미노출 > 안내 모달) > 실제 GPS 확인 > 확인된 동네 표시 > 이 동네로 인증
/// 국내는 GPS 위치만 (지도 선택 없음), 실제 GPS가 서비스 지역 밖 > 지도 선택, 거부·가상 위치·낮은 정확도 > 사유 안내, 인증 성공 > pop(true)
class MyLocationVerificationScreen extends ConsumerStatefulWidget {
  // 진입 전 안내 모달 노출 여부 (공통 인증 확인 경유 > true, 마이페이지 직접 진입 > false)
  final bool isExplanationShown;

  const MyLocationVerificationScreen({super.key, this.isExplanationShown = false});

  @override
  ConsumerState<MyLocationVerificationScreen> createState() => _MyLocationVerificationScreenState();
}

class _MyLocationVerificationScreenState extends ConsumerState<MyLocationVerificationScreen>
    with WidgetsBindingObserver {
  GpsLocationCheckResult? _checkResult;
  bool _isCheckingLocation = false;
  bool _isSaving = false;
  // 설정 화면으로 보낸 뒤 복귀 대기 (복귀 시 권한 요청 없이 1회 재확인)
  bool _isWaitingSettingsReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareVerification());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_isWaitingSettingsReturn) return;
    _isWaitingSettingsReturn = false;
    _checkCurrentLocation(shouldRequestPermission: false);
  }

  /// 진입 준비: 권한 미결정 + 안내 미노출 > 안내 모달 (나중에 > 닫기) > 위치 확인
  Future<void> _prepareVerification() async {
    if (!widget.isExplanationShown) {
      final permission = await ref.read(gpsLocationVerifierProvider).checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        final isExplanationAccepted = await showLocationVerificationExplanation(context);
        if (!mounted) return;
        if (!isExplanationAccepted) {
          Navigator.pop(context, false);
          return;
        }
      }
    }
    await _checkCurrentLocation();
  }

  /// 현재 GPS 위치 확인 (진행 중이면 무시)
  Future<void> _checkCurrentLocation({bool shouldRequestPermission = true}) async {
    if (_isCheckingLocation) return;
    setState(() => _isCheckingLocation = true);
    try {
      final checkResult = await ref
          .read(gpsLocationVerifierProvider)
          .checkCurrentLocation(shouldRequestPermission: shouldRequestPermission);
      if (mounted) setState(() => _checkResult = checkResult);
    } finally {
      if (mounted) setState(() => _isCheckingLocation = false);
    }
  }

  /// 실패 사유에 맞는 시스템 설정 열기 > 복귀 시 재확인
  Future<void> _openSettings() async {
    final failure = _checkResult?.failure;
    if (failure == null) return;
    final isOpened = await ref.read(gpsLocationVerifierProvider).openSettingsFor(failure);
    if (isOpened) _isWaitingSettingsReturn = true;
  }

  /// GPS 위치로 인증 (국내 실제 위치)
  Future<void> _onVerifyPressed() async {
    final checkResult = _checkResult;
    if (checkResult == null || !checkResult.isLocated) return;
    await _saveVerification(
      () => ref.read(locationVerificationProvider.notifier).verifyWithCurrentLocation(checkResult),
    );
  }

  /// 서비스 지역 밖 > 지도에서 고른 동네로 인증
  Future<void> _onManualSelectionVerifyPressed(NLatLng selectedPosition, LocationAddress selectedAddress) async {
    final checkResult = _checkResult;
    if (checkResult == null || !checkResult.isOutsideServiceArea) return;
    await _saveVerification(
      () => ref
          .read(locationVerificationProvider.notifier)
          .verifyWithManualSelection(
            outsideServiceAreaResult: checkResult,
            latitude: selectedPosition.latitude,
            longitude: selectedPosition.longitude,
            selectedAddress: selectedAddress,
          ),
    );
  }

  /// 인증 저장 공통: 진행 중이면 무시 > 저장 > 완료 안내 > pop(true), 실패 > 오류 안내
  Future<void> _saveVerification(Future<void> Function() saveVerifiedLocation) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await saveVerifiedLocation();
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: '동네 인증이 완료되었어요.', type: SnackBarType.success);
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(error), type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(title: '동네 인증', showBottomBorder: true, onBackPressed: () => Navigator.pop(context, false)),
      body: _buildBody(),
    );
  }

  /// 단계별 본문: 확인 중 > 로딩, 확인 전(안내 모달 중) > 빈 화면, 실패 > 사유 안내, 서비스 지역 밖 > 지도 선택, 성공 > 확인된 동네 지도
  Widget _buildBody() {
    final checkResult = _checkResult;
    if (_isCheckingLocation) return _buildCheckingView();
    if (checkResult == null) return const SizedBox.shrink();

    final failure = checkResult.failure;
    if (failure != null) {
      return LocationVerificationFailureView(
        failure: failure,
        onRetryPressed: _checkCurrentLocation,
        onOpenSettingsPressed: _openSettings,
      );
    }

    if (checkResult.isOutsideServiceArea) {
      return LocationVerificationManualSelectionView(
        lookupAddress: ref.read(gpsLocationVerifierProvider).lookupAddress,
        isSaving: _isSaving,
        onVerifyPressed: _onManualSelectionVerifyPressed,
        onRecheckPressed: _checkCurrentLocation,
      );
    }

    return LocationVerificationMapView(
      position: NLatLng(checkResult.latitude!, checkResult.longitude!),
      neighborhoodText: checkResult.address!.siDoSiGunGuEupMyoenDongText,
      isSaving: _isSaving,
      onVerifyPressed: _onVerifyPressed,
      onRecheckPressed: _checkCurrentLocation,
    );
  }

  Widget _buildCheckingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CommonLoadingIndicator(),
          SizedBox(height: 16.h),
          Text(
            '지금 있는 위치를 확인하고 있어요',
            style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
