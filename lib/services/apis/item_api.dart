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
    };

    final files = <String, List<dynamic>>{};
    if (request.itemImages != null && request.itemImages!.isNotEmpty) {
      files['itemImages'] = request.itemImages!;
    }

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      files: files.isEmpty ? null : files,
      isAuthRequired: true,
      onSuccess: (responseData) {
        itemResponse = ItemResponse.fromJson(responseData);
        debugPrint('물품 등록 성공: ${itemResponse.item?.itemName}');
      },
    );

    return itemResponse;
  }

  /// 좋아요 등록/취소 API
  /// `POST /api/item/like/post`
  Future<ItemResponse> postLike(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/like/post';
    late ItemResponse itemResponse;

    final Map<String, dynamic> fields = {
      'itemId': request.itemId,
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        itemResponse = ItemResponse.fromJson(responseData);
        debugPrint('좋아요 상태 변경 성공: ${itemResponse.likeStatus}');
      },
    );

    return itemResponse;
  }

  /// 물품 목록 조회 API
  /// `POST /api/item/get`
  Future<ItemResponse> getItems(ItemRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/item/get';
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
        debugPrint('물품 목록 조회 성공: ${itemResponse.itemDetailPage?.content?.length}개');
      },
    );

    return itemResponse;
  }
} 