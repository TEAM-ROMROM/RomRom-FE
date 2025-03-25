import 'package:flutter/material.dart';

enum loginPlatforms {
  kakao(color: Colors.amber, platformName: 'KAKAO'),
  google(color: Colors.blue, platformName: 'GOOGLE');

  final Color color;
  final String platformName;

  const loginPlatforms({required this.color, required this.platformName});
}
