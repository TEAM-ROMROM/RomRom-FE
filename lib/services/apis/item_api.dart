import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

class ItemApi {
  // 싱글톤 구현
  static final ItemApi _instance = ItemApi._internal();

  factory ItemApi() => _instance;

  ItemApi._internal();

  /// 물품 등록 API
  /// `POST /api/item/post`
  Future<ItemResponse> postItem(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/post';
    late ItemResponse itemResponse;

    final Map<String, dynamic> fields = {
      'itemName': request.itemName,
      'itemDescription': request.itemDescription,
      'itemCategory': request.itemCategory,
      'itemCondition': request.itemCondition,
      'itemTradeOptions': request.itemTradeOptions?.join(','),
      'itemPrice': request.itemPrice?.toString(),
      'itemCustomTags': request.itemCustomTags?.join(','),
      'itemImageUrls': request.itemImageUrls?.join(','),
      'isAiPredictedPrice': request.isAiPredictedPrice,
    };

    // 위치 정보 추가 (필수값)
    if (request.longitude != null) {
      fields['longitude'] = request.longitude!.toString();
      debugPrint('longitude 추가됨: ${request.longitude}');
    } else {
      debugPrint('longitude이 null입니다!');
    }
    if (request.latitude != null) {
      fields['latitude'] = request.latitude!.toString();
      debugPrint('latitude 추가됨: ${request.latitude}');
    } else {
      debugPrint('latitude가 null입니다!');
    }

    debugPrint('최종 전송 필드: $fields');

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        itemResponse = ItemResponse.fromJson(responseData);
        debugPrint('물품 등록 성공: ${itemResponse.item?.itemName ?? request.itemName}');
      },
    );

    return itemResponse;
  }

  /// 좋아요 등록/취소 API
  /// `POST /api/item/like/post`
  Future<ItemResponse> postLike(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/like/post';
    late ItemResponse itemResponse;

    final Map<String, dynamic> fields = {'itemId': request.itemId};

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        itemResponse = ItemResponse.fromJson(responseData);
        debugPrint('좋아요 상태 변경 성공: ${itemResponse.isLiked}');
      },
    );

    return itemResponse;
  }

  /// 물품 리스트 조회 API
  /// `POST /api/item/list/get`
  Future<ItemResponse> getItems(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/list/get';
    late ItemResponse itemResponse;

    final Map<String, dynamic> fields = {
      'pageNumber': request.pageNumber.toString(),
      'pageSize': request.pageSize.toString(),
    };

    if (request.sortField != null) {
      fields['sortField'] = request.sortField!;
    }

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        itemResponse = ItemResponse.fromJson(responseData);
        debugPrint('물품 목록 조회 성공: ${itemResponse.itemPage?.content.length}개');
      },
    );

    return itemResponse;
  }

  /// 물품 상세 조회 API
  /// `POST /api/item/get`
  Future<ItemResponse> getItemDetail(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/get';
    late ItemResponse itemResponse;

    final Map<String, dynamic> fields = {'itemId': request.itemId};

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        itemResponse = ItemResponse.fromJson(responseData);
        debugPrint('물품 상세 조회 성공: ${itemResponse.item?.latitude}, ${itemResponse.item?.longitude}');
      },
    );

    return itemResponse;
  }

  /// 내 물품 목록 조회 API
  /// `POST /api/item/get/my`
  Future<ItemResponse> getMyItems(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/get/my';
    late ItemResponse itemResponse;

    final Map<String, dynamic> fields = {
      'pageNumber': request.pageNumber.toString(),
      'pageSize': request.pageSize.toString(),
      'itemStatus': request.itemStatus,
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        itemResponse = ItemResponse.fromJson(responseData);
        debugPrint(
          '내 물품 목록 조회 성공: '
          '${itemResponse.itemPage?.content.length ?? 0}개',
        );
      },
    );

    return itemResponse;
  }

  /// AI 가격 예측 API
  /// `POST /api/item/price/predict`
  Future<int> pricePredict(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/price/predict';
    int predictedPrice = 0;

    final Map<String, dynamic> fields = {
      'itemName': request.itemName,
      'itemDescription': request.itemDescription,
      'itemCondition': request.itemCondition,
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        // 응답이 int형이거나 Map형일 수 있으므로 안전하게 처리
        if (responseData is int) {
          predictedPrice = responseData;
        } else if (responseData is Map<String, dynamic>) {
          predictedPrice = responseData['data'] ?? 0;
        } else {
          predictedPrice = 0;
        }
        debugPrint('AI 가격 예측 성공: $predictedPrice');
      },
    );

    return predictedPrice;
  }

  /// 물품 삭제 API
  /// `POST /api/item/delete`
  Future<void> deleteItem(String itemId) async {
    const String url = '${AppUrls.baseUrl}/api/item/delete';

    final Map<String, dynamic> fields = {'itemId': itemId};

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('물품 삭제 성공: $itemId');
      },
    );
  }

  /// 물품 수정 API
  /// `POST /api/item/edit`
  Future<void> updateItem(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/edit';

    final Map<String, dynamic> fields = {
      'itemId': request.itemId,
      'itemName': request.itemName,
      'itemDescription': request.itemDescription,
      'itemCategory': request.itemCategory,
      'itemCondition': request.itemCondition,
      'itemTradeOptions': request.itemTradeOptions?.join(','),
      'itemPrice': request.itemPrice?.toString(),
      'itemCustomTags': request.itemCustomTags?.join(','),
      'isAiPredictedPrice': request.isAiPredictedPrice?.toString() ?? 'false',
      'itemImageUrls': request.itemImageUrls?.join(','),
    };

    // 위치 정보 추가 (필수값)
    if (request.longitude != null) {
      fields['longitude'] = request.longitude!.toString();
      debugPrint('longitude 추가됨: ${request.longitude}');
    } else {
      debugPrint('longitude이 null입니다!');
    }
    if (request.latitude != null) {
      fields['latitude'] = request.latitude!.toString();
      debugPrint('latitude 추가됨: ${request.latitude}');
    } else {
      debugPrint('latitude가 null입니다!');
    }

    debugPrint('최종 전송 필드: $fields');

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        debugPrint('물품 수정 성공: ${request.itemName}');
      },
    );
  }

  /// 물품 거래 상태 변경 API
  /// `POST /api/item/status/update`
  Future<ItemResponse> updateItemStatus(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/status/update';
    late ItemResponse itemResponse;

    final Map<String, dynamic> fields = {'itemId': request.itemId, 'itemStatus': request.itemStatus};

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        itemResponse = ItemResponse.fromJson(responseData);
        debugPrint('물품 상태 변경 성공: ${request.itemStatus}');
      },
    );

    return itemResponse;
  }

  /// 좋아요 물품 목록 조회
  /// `POST /api/item/like/get`
  Future<ItemResponse> getLikeList(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/like/get';
    late ItemResponse itemResponse;

    final Map<String, dynamic> fields = {
      'pageNumber': request.pageNumber.toString(),
      'pageSize': request.pageSize.toString(),
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        itemResponse = ItemResponse.fromJson(responseData);
        debugPrint('좋아요 목록 조회 성공: ${itemResponse.itemPage?.content.length}개');
      },
    );

    return itemResponse;
  }
}
