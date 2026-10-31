// lib/models/apis/objects/home_popup.dart

/// 홈 화면 공지·이벤트 팝업 (백엔드 HomePopup 엔티티, #749)
/// 키 미확정 > 전 필드 nullable, 타입이 다른 값은 null 처리
class HomePopup {
  final String? homePopupId;
  final String? title;
  final String? description;
  final String? imageUrl;
  // 외부 https:// 또는 앱 내부 romrom:// 딥링크
  final String? linkUrl;
  // 클수록 우선 (서버가 최상위 1개만 반환)
  final int? priority;
  final bool? isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  const HomePopup({
    this.homePopupId,
    this.title,
    this.description,
    this.imageUrl,
    this.linkUrl,
    this.priority,
    this.isActive,
    this.startDate,
    this.endDate,
  });

  /// JSON > HomePopup (isActive는 Jackson primitive boolean 직렬화 키 active도 허용)
  factory HomePopup.fromJson(Map<String, dynamic> json) {
    return HomePopup(
      homePopupId: _readText(json['homePopupId']),
      title: _readText(json['title']),
      description: _readText(json['description']),
      imageUrl: _readText(json['imageUrl']),
      linkUrl: _readText(json['linkUrl']),
      priority: _readInt(json['priority']),
      isActive: _readBool(json['isActive'] ?? json['active']),
      startDate: _readDateTime(json['startDate']),
      endDate: _readDateTime(json['endDate']),
    );
  }

  /// 문자열 아니거나 공백뿐이면 null
  static String? _readText(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _readInt(Object? value) => value is num ? value.toInt() : null;

  static bool? _readBool(Object? value) => value is bool ? value : null;

  /// 날짜: ISO 문자열 또는 LocalDateTime 배열([yyyy, M, d, H, m, s]) > DateTime
  static DateTime? _readDateTime(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is List && value.length >= 3 && value.every((part) => part is int)) {
      final parts = value.cast<int>();
      int partAt(int index) => parts.length > index ? parts[index] : 0;
      return DateTime(parts[0], parts[1], parts[2], partAt(3), partAt(4), partAt(5));
    }
    return null;
  }
}
