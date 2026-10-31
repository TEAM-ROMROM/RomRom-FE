import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/apis/promotion_api.dart';

void main() {
  group('PromotionApi.promoteItem', () {
    test('multipart 필드 itemId 전송 > 응답 item의 노출 필드 파싱', () async {
      String? sentUrl;
      Map<String, dynamic>? sentFields;
      final promotionApi = PromotionApi(
        sendMultipartRequest: ({required url, fields, required onSuccess}) async {
          sentUrl = url;
          sentFields = fields;
          final responseBody = {
            'item': {'itemId': 'item-1', 'promotionExpiresAt': '2026-11-01T12:30:00', 'isPromoted': true},
          };
          onSuccess(responseBody);
          return http.Response(jsonEncode(responseBody), 200);
        },
      );

      final promotedItem = await promotionApi.promoteItem('item-1');

      expect(sentUrl, '${AppUrls.baseUrl}/api/item/promote');
      expect(sentFields, {'itemId': 'item-1'});
      expect(promotedItem?.itemId, 'item-1');
      expect(promotedItem?.isPromoted, isTrue);
      expect(promotedItem?.promotionExpiresAt, DateTime(2026, 11, 1, 12, 30));
    });

    test('전송 실패 예외는 그대로 전달', () async {
      final promotionApi = PromotionApi(
        sendMultipartRequest: ({required url, fields, required onSuccess}) async => throw Exception('boom'),
      );

      expect(promotionApi.promoteItem('item-1'), throwsException);
    });
  });
}
