import 'package:flutter/material.dart';

/// 앱 전역 애니메이션 토큰
///
/// Duration과 Curve를 의미 있는 이름으로 중앙 관리.
/// 하드코딩된 Duration(milliseconds: N), Curves.easeInOut 사용 금지.
/// 반드시 이 클래스의 상수를 사용할 것.
class AppMotion {
  AppMotion._();

  // ─────────────────────────────────────────────
  // Duration 토큰 (5단계)
  // ─────────────────────────────────────────────

  /// 100ms — 터치 피드백, 즉각 반응
  static const Duration instant = Duration(milliseconds: 100);

  /// 200ms — 기본 UI 전환, 스크롤 반응, 스켈레톤 fade
  static const Duration fast = Duration(milliseconds: 200);

  /// 300ms — 카드/리스트 등장, 상태 변경, 탭 전환
  static const Duration normal = Duration(milliseconds: 300);

  /// 400ms — 페이지 전환, 모달 등장/퇴장
  static const Duration slow = Duration(milliseconds: 400);

  /// 500ms — 온보딩, 특수 진입 (일반 UI에는 사용 금지)
  static const Duration emphasis = Duration(milliseconds: 500);

  // ─────────────────────────────────────────────
  // Curve 토큰 — 토스 스타일 (빠르게 출발해 길게 감속, 끝이 튀지 않음)
  // ─────────────────────────────────────────────

  /// 일반적인 상태 변화 — 토글, 색상 전환 (대칭 ease, easeInOut보다 끝이 부드러움)
  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1.0);

  /// 등장/진입 — 리스트 아이템, 카드 등장 (출발 빠르고 끝을 길게 감속)
  static const Curve entry = Cubic(0.2, 0.0, 0.0, 1.0);

  /// 감속 — 컨텍스트 메뉴, 오버레이, 시트 등장 (강한 감속)
  static const Curve decelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// 가속 — 오버레이 닫힘, decelerate의 역방향
  static const Curve accelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// 살짝 넘쳤다 돌아오는 강조 — 좋아요·선택 확정 (튕김 1회, 탄성 반복 없음)
  static const Curve springOut = Cubic(0.34, 1.36, 0.64, 1.0);

  // ─────────────────────────────────────────────
  // Spring 토큰 — 물리 기반 (손 뗀 뒤 복귀·스냅)
  // ─────────────────────────────────────────────

  /// 버튼·카드 눌림 복귀 — 빠르고 거의 튀지 않음 (감쇠비 0.8)
  static final SpringDescription pressSpring = SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 400.0,
    ratio: 0.8,
  );

  /// 페이지·카드 스냅 — 피드 넘김, 드래그 후 제자리 (감쇠비 1.0, 넘침 없음)
  static final SpringDescription snapSpring = SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 180.0,
    ratio: 1.0,
  );

  // ─────────────────────────────────────────────
  // 스켈레톤 shimmer 설정
  // ─────────────────────────────────────────────

  /// 리스트 stagger 간격 — 아이템 인덱스 당 딜레이 (ms)
  static const int staggerDelayMs = 30;
}
