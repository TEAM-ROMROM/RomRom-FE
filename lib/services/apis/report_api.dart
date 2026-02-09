import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

/// 신고 관련 API
class ReportApi {
  // 싱글톤 구현
  static final ReportApi _instance = ReportApi._internal();

  factory ReportApi() => _instance;

  ReportApi._internal();

  /// 아이템 신고 API
  /// POST /api/report/item/post
  Future<void> reportItem({required String itemId, required Set<int> itemReportReasons, String? extraComment}) async {
    const String url = '${AppUrls.baseUrl}/api/report/item/post';

    final Map<String, dynamic> fields = {
      'itemId': itemId,
      'itemReportReasons': itemReportReasons.join(','),
      if (extraComment != null && extraComment.isNotEmpty) 'extraComment': extraComment,
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('신고 성공');
      },
    );
  }

  /// 회원 신고 API
  /// POST /api/report/member/post
  Future<void> reportMember({
    required String memberId,
    required Set<int> memberReportReasons,
    String? extraComment,
  }) async {
    const String url = '${AppUrls.baseUrl}/api/report/member/post';

    final Map<String, dynamic> fields = {
      'memberId': memberId,
      'memberReportReasons': memberReportReasons.join(','),
      if (extraComment != null && extraComment.isNotEmpty) 'extraComment': extraComment,
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('회원 신고 성공');
      },
    );
  }
}
