import 'package:flutter/material.dart';

enum Platforms {
  kakao(color: Colors.amber, platformName: 'KAKAO'),
  google(color: Colors.blue, platformName: 'GOOGLE');

  final Color color;
  final String platformName;

  const Platforms({required this.color, required this.platformName});
}
