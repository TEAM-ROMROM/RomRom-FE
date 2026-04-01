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
  // Curve 토큰 (4종)
  // ─────────────────────────────────────────────

  /// 일반적인 상태 변화 — 토글, 색상 전환
  static const Curve standard = Curves.easeInOut;

  /// 등장/진입 — 리스트 아이템, 카드 등장 (빠른 시작, 부드러운 끝)
  static const Curve entry = Curves.easeOut;

  /// 감속 — 컨텍스트 메뉴, 오버레이 (물리적 자연스러움)
  static const Curve decelerate = Curves.easeOutCubic;

  /// 버튼 눌림 spring back — AppPressable의 복귀 애니메이션
  static const Curve springOut = ElasticOutCurve(0.5);

  // ─────────────────────────────────────────────
  // 스켈레톤 shimmer 설정
  // ─────────────────────────────────────────────

  /// 리스트 stagger 간격 — 아이템 인덱스 당 딜레이 (ms)
  static const int staggerDelayMs = 30;
}
