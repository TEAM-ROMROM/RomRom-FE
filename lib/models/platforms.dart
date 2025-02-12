import 'package:flutter/material.dart';

enum Platforms {
  KAKAO(color: Colors.amber),
  GOOGLE(color: Colors.blue);

  final Color color;

  const Platforms({required this.color});
}
