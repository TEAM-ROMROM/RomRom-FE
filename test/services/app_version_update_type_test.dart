import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/utils/app_version_comparison.dart';

/// 현재 버전 <-> 서버 최소·최신 버전 > 강제·권장·불필요
void main() {
  test('최소 버전 미달 > 강제', () {
    expect(
      resolveUpdateType(currentVersion: '1.9.0', minimumVersion: '1.10.0', latestVersion: '1.10.129'),
      UpdateType.force,
    );
  });

  test('최소 이상, 최신 미달 > 권장', () {
    expect(
      resolveUpdateType(currentVersion: '1.10.100', minimumVersion: '1.10.0', latestVersion: '1.10.129'),
      UpdateType.recommend,
    );
  });

  test('최신 이상 > 불필요', () {
    expect(
      resolveUpdateType(currentVersion: '1.10.129', minimumVersion: '1.10.0', latestVersion: '1.10.129'),
      UpdateType.none,
    );
  });

  test('최신 버전 형식 오류 > 강제 판정은 유지, 권장은 생략', () {
    expect(
      resolveUpdateType(currentVersion: '1.10.1', minimumVersion: '1.10.0', latestVersion: 'latest'),
      UpdateType.none,
    );
    expect(
      resolveUpdateType(currentVersion: '1.9.0', minimumVersion: '1.10.0', latestVersion: 'latest'),
      UpdateType.force,
    );
  });

  test('최소 버전 v 접두어·공백·접미사 > 정상 강제 판정', () {
    for (final minimumVersion in ['v1.10.10', 'V1.10.10', ' 1.10.10 ', '1.10.10-beta', '1.10.10+12']) {
      expect(
        resolveUpdateType(currentVersion: '1.10.9', minimumVersion: minimumVersion, latestVersion: '1.10.10'),
        UpdateType.force,
        reason: minimumVersion,
      );
    }
  });

  test('최소 버전 빈 값·형식 오류 > 강제 판정 제외, 최신 버전 판정 유지', () {
    for (final minimumVersion in ['', '   ', 'latest', '1..10', '1.10.x']) {
      expect(
        resolveUpdateType(currentVersion: '1.10.9', minimumVersion: minimumVersion, latestVersion: '1.10.10'),
        UpdateType.recommend,
        reason: '"$minimumVersion"',
      );
      expect(
        resolveUpdateType(currentVersion: '1.10.10', minimumVersion: minimumVersion, latestVersion: '1.10.10'),
        UpdateType.none,
        reason: '"$minimumVersion"',
      );
    }
  });

  test('설치 버전 형식 오류 > 판정 생략 (차단하지 않음)', () {
    expect(resolveUpdateType(currentVersion: '', minimumVersion: '1.10.0', latestVersion: '1.10.10'), UpdateType.none);
  });
}
