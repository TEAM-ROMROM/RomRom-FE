// lib/models/term_contents.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:romrom_fe/enums/term_type.dart';

// 약관 내용 모델
class TermContents {
  final String title;
  final String content;

  const TermContents({
    required this.title,
    required this.content,
  });

  // JSON에서 TermContents 생성
  factory TermContents.fromJson(Map<String, dynamic> json) {
    return TermContents(
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }

  // TermContents를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }

  // ===== 약관 로딩 로직 =====
  
  // 캐시 저장용
  static Map<TermsType, TermContents>? _cache;

  // 모든 약관 내용 로드 (캐시 포함)
  static Future<Map<TermsType, TermContents>> loadAll() async {
    if (_cache != null) return _cache!;

    final Map<TermsType, TermContents> terms = {};

    for (final termType in TermsType.values) {
      terms[termType] = await _loadSingle(termType);
    }

    _cache = terms;
    return terms;
  }

  // 특정 약관만 로드
  static Future<TermContents> loadSingle(TermsType termType) async {
    final allTerms = await loadAll();
    return allTerms[termType]!;
  }

  // JSON 파일에서 개별 약관 로드
  static Future<TermContents> _loadSingle(TermsType termType) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/terms/${termType.contentKey}.json'
      );
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return TermContents.fromJson(jsonData);
    } catch (e) {
      // 로드 실패시 기본값 반환
      return TermContents(
        title: termType.title,
        content: '약관을 불러오는 중 오류가 발생했습니다.',
      );
    }
  }

  // 캐시 초기화
  static void clearCache() {
    _cache = null;
  }
}