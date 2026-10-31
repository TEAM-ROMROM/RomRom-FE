import 'package:http/http.dart' as http;
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

/// multipart 전송 함수 (ApiClient.sendMultipartRequest 서명 일부, 테스트 대역 주입용)
typedef PromotionMultipartSender =
    Future<http.Response> Function({
      required String url,
      Map<String, dynamic>? fields,
      required Function(dynamic) onSuccess,
    });

/// 우선노출(롬업) API: 활성화 요청 (결과 해석은 PromotionNotifier)
class PromotionApi {
  final PromotionMultipartSender _sendMultipartRequest;

  PromotionApi({PromotionMultipartSender? sendMultipartRequest})
    : _sendMultipartRequest = sendMultipartRequest ?? _sendWithApiClient;

  static Future<http.Response> _sendWithApiClient({
    required String url,
    Map<String, dynamic>? fields,
    required Function(dynamic) onSuccess,
  }) => ApiClient.sendMultipartRequest(url: url, fields: fields, onSuccess: onSuccess);

  /// 우선노출 활성화 > 활성화된 물품 (promotionExpiresAt·isPromoted 포함)
  /// `POST /api/item/promote` multipart(@ModelAttribute) itemId, JSON 본문은 415
  /// 2xx 외 응답은 ApiException (errorCode로 원인 구분)
  Future<Item?> promoteItem(String itemId) async {
    final String url = '${AppUrls.baseUrl}/api/item/promote';
    Item? promotedItem;

    await _sendMultipartRequest(
      url: url,
      fields: {'itemId': itemId},
      onSuccess: (responseData) => promotedItem = ItemResponse.fromJson(responseData).item,
    );

    return promotedItem;
  }
}
