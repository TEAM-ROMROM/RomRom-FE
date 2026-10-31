// 홈 카드 덱 모션 값: 펼침·뽑기·복귀·드롭존·AI 하이라이트 시간과 곡선 (전부 AppMotion 토큰 기준)
import 'package:flutter/physics.dart';
import 'package:romrom_fe/models/app_motion.dart';

class CardHandMotion {
  CardHandMotion._();

  // ─────────────────────────────────────────────
  // 덱 펼침·카드 상태 전환
  // ─────────────────────────────────────────────

  // 화면 진입 후 덱 첫 펼침까지 한 박자 (500ms)
  static const Duration fanStartDelay = AppMotion.emphasis;

  // 덱 첫 펼침 (500ms, 강한 감속)
  static const Duration fanDuration = AppMotion.emphasis;

  // 카드 뽑기: 손가락 위로 떠오름·확대·기울기 해제 (200ms)
  static const Duration pullLiftDuration = AppMotion.fast;

  // 누름·선택 확대 (1.0 > 1.05 > 1.12)
  static const Duration cardScaleDuration = AppMotion.fast;

  // 카드 테두리·그림자 전환 (뽑힌 카드는 즉각 반응)
  static const Duration cardDecorationDuration = AppMotion.fast;
  static const Duration pulledCardDecorationDuration = AppMotion.instant;

  // 선택 중 배경 어둡게 (페이드 인·아웃)
  static const Duration dimOverlayFadeDuration = AppMotion.fast;

  // 드롭존 진입·이탈 시 그림자 강도 전환
  static const Duration dropZoneHighlightDuration = AppMotion.fast;

  // 드롭 직후 카드를 드롭존에 잠시 머물게 한 뒤 복귀 (300ms)
  static const Duration dropReturnDelay = AppMotion.normal;

  // 드롭 안내 아이콘 위아래 반복 반주기 (500ms)
  static const Duration dropGuideIconHalfCycleDuration = AppMotion.emphasis;

  // ─────────────────────────────────────────────
  // AI 추천 하이라이트
  // ─────────────────────────────────────────────

  // glow 밝기 반복 반주기 (1400ms, 느린 호흡)
  static final Duration highlightPulseHalfCycleDuration = AppMotion.slow * 3.5;

  // 추천 카드 위로 떠오름 (500ms) / 해제 시 내려앉음 (800ms)
  static const Duration highlightFloatUpDuration = AppMotion.emphasis;
  static final Duration highlightFloatDownDuration = AppMotion.slow * 2;

  // 재정렬 보간 전체 (900ms: 집결 40% > 홀드 10% > 팬아웃 50%, 구간은 CardHandGeometry)
  static final Duration reorderDuration = AppMotion.slow + AppMotion.emphasis;

  // 추천 카드가 왼쪽 끝에 오도록 궤도 이동 (400ms)
  static const Duration highlightOrbitDuration = AppMotion.slow;

  // ─────────────────────────────────────────────
  // 놓은 뒤 spring 복귀 (AppMotion.snapSpring, 감쇠비 1.0)
  // ─────────────────────────────────────────────

  // 당김 변위 spring 종료 판정 (0.5px 이내, 10px/s 이하 > 화면상 정지)
  static const Tolerance pullOffsetSpringTolerance = Tolerance(distance: 0.5, velocity: 10.0);

  // 뽑기 진행도(0~1) spring 종료 판정
  static const Tolerance pullProgressSpringTolerance = Tolerance(distance: 0.005, velocity: 0.05);

  // 궤도 각도(라디안) 관성·spring 종료 판정
  static const Tolerance orbitSimulationTolerance = Tolerance(distance: 0.0005, velocity: 0.005);
}
