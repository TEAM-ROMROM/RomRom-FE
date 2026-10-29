import 'package:romrom_fe/enums/app_update_type.dart';

/// 스플래시 시작 결과: 중단 / 강제 업데이트 / 다음 화면 중 하나
class SplashStartupResult<T> {
  final bool isAborted;
  final bool isForcedUpdate;
  final T? nextScreen;

  const SplashStartupResult.aborted() : isAborted = true, isForcedUpdate = false, nextScreen = null;

  const SplashStartupResult.forcedUpdate() : isAborted = false, isForcedUpdate = true, nextScreen = null;

  const SplashStartupResult.nextScreen(T this.nextScreen) : isAborted = false, isForcedUpdate = false;
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
  return SplashStartupResult<T>.nextScreen(results[0] as T);
}
