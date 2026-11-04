import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/error_code.dart';
import 'package:romrom_fe/enums/location_verification_purpose.dart';
import 'package:romrom_fe/providers/location_verification_provider.dart';
import 'package:romrom_fe/screens/my_page/my_location_verification_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/location_verification/location_verification_explanation_modal.dart';

// 호출부가 목적 enum을 따로 import 하지 않게 함께 공개
export 'package:romrom_fe/enums/location_verification_purpose.dart';

final locationVerificationGateProvider = Provider<LocationVerificationGate>((ref) => LocationVerificationGate(ref));

/// 동네 인증 필요 기능 공통 진입 확인: 인증됨 > 통과, 미인증 > 안내 모달 > GPS 인증 화면 > 인증 결과
/// 거부·취소 시 해당 기능만 중단 (앱·화면 차단 없음, 자동 재요청 없음)
class LocationVerificationGate {
  final Ref _ref;
  final Future<bool?> Function(BuildContext context) _openVerificationScreen;

  // 안내·인증 진행 중 (연속 탭 시 모달 중복 방지)
  bool _isInProgress = false;

  LocationVerificationGate(this._ref, {Future<bool?> Function(BuildContext context)? openVerificationScreen})
    : _openVerificationScreen = openVerificationScreen ?? _navigateToVerificationScreen;

  /// [purpose] 기능 사용 전 동네 인증 확인 (통과 > true, 취소·실패·진행 중 > false)
  Future<bool> ensureVerified(BuildContext context, {required LocationVerificationPurpose purpose}) async {
    if (_isInProgress) return false;
    _isInProgress = true;
    try {
      if (await _ref.read(locationVerificationProvider.notifier).isCurrentMemberVerified()) return true;
      if (!context.mounted) return false;

      final isExplanationAccepted = await showLocationVerificationExplanation(context, purpose: purpose);
      if (!isExplanationAccepted || !context.mounted) return false;

      return await _openVerificationScreen(context) == true;
    } finally {
      // (성공·실패 공통)
      _isInProgress = false;
    }
  }

  /// 서버 거부(LOCATION_NOT_VERIFIED) 처리: 서버 상태 재조회·로컬 기록 삭제 > 안내 모달 > 인증 화면
  /// 해당 오류 > true (호출부는 오류 안내 생략), 그 외 오류 > false (호출부가 기존 오류 안내)
  Future<bool> recoverFromServerRejection(
    BuildContext context,
    Object error, {
    required LocationVerificationPurpose purpose,
  }) async {
    if (ErrorUtils.getErrorCode(error) != ErrorCode.locationNotVerified) return false;
    await _ref.read(locationVerificationProvider.notifier).resyncAfterServerRejection();
    if (context.mounted) await ensureVerified(context, purpose: purpose);
    return true;
  }

  /// GPS 인증 화면 (안내 모달 노출 완료 상태로 진입, 인증 성공 > true)
  static Future<bool?> _navigateToVerificationScreen(BuildContext context) =>
      context.navigateTo<bool>(screen: const MyLocationVerificationScreen(isExplanationShown: true));
}
