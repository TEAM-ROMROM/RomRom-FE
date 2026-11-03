import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/utils/error_utils.dart';

// 시작 실패 안내 문구 (토큰 재발급 연결 실패·서버 오류, 그 외 오류)
const String splashRetryableFailureDescription = '인터넷 연결을 확인하거나\n잠시 후 다시 시도해 주세요';
const String splashUnknownFailureDescription = '잠시 후 다시 시도해 주세요';

/// 시작 단계 재시도 가능 실패 (토큰 재발급 연결 실패·서버 5xx, refresh 토큰은 유지)
class SplashStartupRetryableException implements Exception {
  const SplashStartupRetryableException();

  @override
  String toString() => 'SplashStartupRetryableException: token reissue retryable failure';
}

// 재시도 가능한 4xx: 408 요청 시간 초과, 429 요청 과다
const Set<int> _retryableClientErrorStatusCodes = {408, 429};

/// 토큰 재발급 성공 후 회원 정보 조회 오류 > 다시 시도 여부
/// 연결 실패·시간 초과·5xx·408·429 > 다시 시도, 그 외(4xx·로컬 오류) > 로그인 화면
bool isRetryableMemberLoadError(Object error) {
  if (error is ApiException) {
    return error.statusCode >= 500 || _retryableClientErrorStatusCodes.contains(error.statusCode);
  }
  return ErrorUtils.isNetworkError(error);
}

/// 시작 실패 오류 > 다시 시도 화면 설명 문구
String describeStartupFailure(Object error) {
  if (error is SplashStartupRetryableException) return splashRetryableFailureDescription;
  if (ErrorUtils.isNetworkError(error)) return ErrorUtils.networkErrorMessage;
  return splashUnknownFailureDescription;
}

/// 스플래시 시작 결과: 중단 / 강제 업데이트 / 다음 화면(+ 권장 업데이트 여부) 중 하나
class SplashStartupResult<T> {
  final bool isAborted;
  final bool isForcedUpdate;
  // 최신 버전 아님 (닫을 수 있는 안내 대상, 노출 주기는 화면 판단)
  final bool isRecommendedUpdate;
  final T? nextScreen;

  const SplashStartupResult.aborted()
    : isAborted = true,
      isForcedUpdate = false,
      isRecommendedUpdate = false,
      nextScreen = null;

  const SplashStartupResult.forcedUpdate()
    : isAborted = false,
      isForcedUpdate = true,
      isRecommendedUpdate = false,
      nextScreen = null;

  const SplashStartupResult.nextScreen(T this.nextScreen, {this.isRecommendedUpdate = false})
    : isAborted = false,
      isForcedUpdate = false;
}

/// 스플래시 시작 순서: 버전 확인(최소 노출 시간과 병렬) > 강제 업데이트면 즉시 반환 > 초기 화면 결정 > 최소 노출 시간 대기
/// 초기 화면 결정은 버전 확인 뒤 실행 (토큰 재발급·제재 응답의 화면 이동이 강제 업데이트 화면을 덮지 않게)
Future<SplashStartupResult<T>> runSplashStartupSequence<T>({
  required Future<UpdateType> Function() checkUpdateType,
  required Future<T> Function() determineInitialScreen,
  required bool Function() isAborted,
  required Duration minimumSplashDuration,
}) async {
  // 최소 노출 시간: 버전 확인과 동시에 시작
  final Future<void> minimumSplashDelay = Future<void>.delayed(minimumSplashDuration);

  // 버전 확인 (강제 업데이트가 일반 경로보다 우선)
  final UpdateType updateType = await checkUpdateType();
  if (isAborted()) return SplashStartupResult<T>.aborted();
  if (updateType == UpdateType.force) return SplashStartupResult<T>.forcedUpdate();

  // 초기 화면 결정 + 최소 노출 시간 (오류는 두 Future 완료 후 전달)
  final List<Object?> results = await Future.wait<Object?>([determineInitialScreen(), minimumSplashDelay]);
  if (isAborted()) return SplashStartupResult<T>.aborted();
  return SplashStartupResult<T>.nextScreen(results[0] as T, isRecommendedUpdate: updateType == UpdateType.recommend);
}
