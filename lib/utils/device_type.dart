/// 디바이스 타입 판별 유틸
///
/// main.dart에서 앱 시작 시 [initDeviceType]을 호출하여 초기화.
/// 이후 어디서든 [isTablet]으로 태블릿 여부를 확인할 수 있음.
///
/// 기준: 화면 너비 600px 초과 시 태블릿
library;

import 'package:flutter/widgets.dart';

bool isTablet = false;

/// 앱 시작 시 한 번 호출하여 디바이스 타입 초기화
void initDeviceType(BuildContext context) {
  isTablet = MediaQuery.of(context).size.width > 600;
}
