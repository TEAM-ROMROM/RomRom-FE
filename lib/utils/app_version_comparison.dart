import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/app_update_type.dart';

// 버전 형식: 앞 v/V 허용, 숫자 마디(.) 1개 이상, 뒤 -beta·+12 접미사 무시
final RegExp _versionPattern = RegExp(r'^[vV]?(\d+(?:\.\d+)*)(?:[-+].*)?$');
// 로그에 남길 서버 버전 값 최대 길이
const int _maximumLoggedVersionLength = 20;
// 로그 출력 불가 문자 (출력 가능 ASCII 외 전부)
final RegExp _nonPrintablePattern = RegExp(r'[^\x20-\x7E]');

/// 버전 문자열 > 숫자 마디 목록 ("v1.10.10-beta" > [1, 10, 10]), 형식 오류·빈 값 null
List<int>? parseVersionSegments(String rawVersion) {
  final match = _versionPattern.firstMatch(rawVersion.trim());
  if (match == null) return null;
  final segments = match.group(1)!.split('.').map(int.tryParse).toList();
  if (segments.contains(null)) return null; // 64비트 초과 숫자
  return segments.cast<int>();
}

/// 현재 마디 < 대상 마디 이면 true (마디 수 다르면 짧은 쪽 0 채움, 같으면 false)
bool isVersionSegmentsLower(List<int> currentSegments, List<int> targetSegments) {
  final segmentCount = currentSegments.length > targetSegments.length ? currentSegments.length : targetSegments.length;
  for (int index = 0; index < segmentCount; index++) {
    final currentSegment = index < currentSegments.length ? currentSegments[index] : 0;
    final targetSegment = index < targetSegments.length ? targetSegments[index] : 0;
    if (currentSegment != targetSegment) return currentSegment < targetSegment;
  }
  return false;
}

/// 현재 <-> 최소 버전 미달 > force, 최신 버전 미달 > recommend, 그 외 none
/// 형식 오류: 설치 버전 > 판정 생략(none), 최소 버전 > 강제 판정만 생략, 최신 버전 > 권장 판정만 생략
UpdateType resolveUpdateType({
  required String currentVersion,
  required String minimumVersion,
  required String latestVersion,
}) {
  final currentSegments = parseVersionSegments(currentVersion);
  if (currentSegments == null) {
    debugPrint('[app version] check skipped : installed version invalid ${_describeVersionForLog(currentVersion)}');
    return UpdateType.none;
  }

  // 강제 판정 (최소 버전)
  final minimumSegments = parseVersionSegments(minimumVersion);
  if (minimumSegments == null) {
    debugPrint('[app version] minimum version ignored : invalid ${_describeVersionForLog(minimumVersion)}');
  } else if (isVersionSegmentsLower(currentSegments, minimumSegments)) {
    return UpdateType.force;
  }

  // 권장 판정 (최신 버전)
  final latestSegments = parseVersionSegments(latestVersion);
  if (latestSegments == null) {
    debugPrint('[app version] latest version ignored : invalid ${_describeVersionForLog(latestVersion)}');
    return UpdateType.none;
  }
  return isVersionSegmentsLower(currentSegments, latestSegments) ? UpdateType.recommend : UpdateType.none;
}

/// 로그용 버전 값 정리 (제어문자·비ASCII > ?, 20자 제한, 따옴표 감쌈)
String _describeVersionForLog(String rawVersion) {
  final printableVersion = rawVersion.replaceAll(_nonPrintablePattern, '?');
  final trimmedVersion = printableVersion.length > _maximumLoggedVersionLength
      ? printableVersion.substring(0, _maximumLoggedVersionLength)
      : printableVersion;
  return '"$trimmedVersion"';
}
