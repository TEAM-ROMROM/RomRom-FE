import 'package:flutter/material.dart';

enum LoginPlatforms {
  kakao(color: Colors.amber, platformName: 'KAKAO'),
  google(color: Colors.blue, platformName: 'GOOGLE');

  final Color color;
  final String platformName;

  const LoginPlatforms({required this.color, required this.platformName});
}
