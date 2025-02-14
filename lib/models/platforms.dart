import 'package:flutter/material.dart';

// TODO : 디자인 나오면 color 수정
enum Platforms {
  KAKAO(color: Colors.amber),
  GOOGLE(color: Colors.blue);

  final Color color;

  const Platforms({required this.color});
}
