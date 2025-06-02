import 'package:flutter/material.dart';

/// 온보딩 단계를 정의하는 enum
enum OnboardingSteps {
  userInfo(
    step: 1,
    title: '기본정보 입력',
    subtitle: '프로필 작성을 위한 정보를 입력해주세요',
  ),
  locationVerification(
    step: 2,
    title: '동네 인증하기',
    subtitle: '내 위치를 인증해주세요',
  ),
  categorySelection(
    step: 3,
    title: '카테고리 선택',
    subtitle: '관심있는 분야를 선택해주세요!',
  );

  final int step;
  final String title;
  final String subtitle;

  const OnboardingSteps({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  /// 단계 번호로 OnboardingSteps 가져오기
  static OnboardingSteps fromStep(int step) {
    return values.firstWhere(
      (element) => element.step == step,
      orElse: () => userInfo,
    );
  }
}