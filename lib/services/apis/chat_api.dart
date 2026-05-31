// lib/services/apis/chat_api.dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/objects/api_pageable.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/apis/objects/chat_user_state.dart';
import 'package:romrom_fe/models/apis/responses/chat_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 채팅 관련 API
class ChatApi {
  // 싱글톤 구현
  static final ChatApi _instance = ChatApi._internal();
  factory ChatApi() => _instance;
  ChatApi._internal();

  /// 채팅방 생성 API
  /// POST /api/chat/rooms/create
  Future<ChatRoom> createChatRoom({required String opponentMemberId, required String tradeRequestHistoryId}) async {
    final String url = '${AppUrls.baseUrl}/api/chat/rooms/create';
    late ChatRoom chatRoom;

    final Map<String, dynamic> fields = {
      'opponentMemberId': opponentMemberId,
      'tradeRequestHistoryId': tradeRequestHistoryId,
    };

    http.Response response = await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      chatRoom = ChatRoomResponse.fromJson(responseData).chatRoom!;
      debugPrint('채팅방 생성 성공: ${chatRoom.chatRoomId}');
    } else {
      throw Exception('채팅방 생성 실패: ${response.statusCode}');
    }

    return chatRoom;
  }

  /// 본인 채팅방 목록 조회 API
  /// POST /api/chat/rooms/get
  Future<PagedChatRoomDetail> getChatRooms({int pageNumber = 0, int pageSize = 8}) async {
    final String url = '${AppUrls.baseUrl}/api/chat/rooms/get';
    late PagedChatRoomDetail pagedChatRooms;

    final Map<String, dynamic> fields = {'pageNumber': pageNumber.toString(), 'pageSize': pageSize.toString()};

    http.Response response = await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // 백엔드 응답 구조: { "chatRoomDetailDtoPage": { "content": [...], \"last\": false, ... } }
      final chatRoomsData = responseData['chatRoomDetailDtoPage'];

      if (chatRoomsData != null) {
        // Spring Page 구조 파싱
        final content = (chatRoomsData['content'] as List)
            .map((e) => ChatRoomDetailDto.fromJson(e as Map<String, dynamic>))
            .toList();

        final isLast = chatRoomsData['last'] as bool? ?? true;

        pagedChatRooms = PagedChatRoomDetail(
          content: content,
          pageable: ApiPageable(
            pageSize: (chatRoomsData['size'] as num?)?.toInt() ?? pageSize,
            pageNumber: (chatRoomsData['number'] as num?)?.toInt() ?? pageNumber,
          ),
          last: isLast,
        );

        debugPrint('채팅방 목록 조회 성공: ${pagedChatRooms.content.length}개');
      } else {
        // chatRooms 필드가 없는 경우 빈 목록 반환
        pagedChatRooms = PagedChatRoomDetail(
          content: [],
          pageable: ApiPageable(pageSize: pageSize, pageNumber: pageNumber),
        );
        debugPrint('채팅방 목록이 비어있습니다');
      }
    } else {
      throw Exception('채팅방 목록 조회 실패: ${response.statusCode}');
    }

    return pagedChatRooms;
  }

  /// 특정 물품의 채팅 상대 목록 조회 API
  /// POST /api/chat/rooms/get/item (itemId 필터)
  Future<PagedChatRoomDetail> getChatRoomsByItemId({required String itemId, int pageSize = 50}) async {
    final String url = '${AppUrls.baseUrl}/api/chat/rooms/get/item';

    final Map<String, dynamic> fields = {'pageNumber': '0', 'pageSize': pageSize.toString(), 'itemId': itemId};

    final http.Response response = await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('물품 채팅 상대 조회 실패: ${response.statusCode}');
    }

    final Map<String, dynamic> responseData = jsonDecode(response.body);
    final chatRoomsData = responseData['chatRoomDetailDtoPage'] as Map<String, dynamic>?;
    if (chatRoomsData == null) {
      return PagedChatRoomDetail(
        content: [],
        pageable: ApiPageable(pageSize: pageSize, pageNumber: 0),
      );
    }

    final rawContent = chatRoomsData['content'];
    final content = rawContent is List
        ? rawContent.map((e) => ChatRoomDetailDto.fromJson(e as Map<String, dynamic>)).toList()
        : <ChatRoomDetailDto>[];
    final isLast = chatRoomsData['last'] as bool? ?? true;

    return PagedChatRoomDetail(
      content: content,
      pageable: ApiPageable(pageSize: pageSize, pageNumber: 0),
      last: isLast,
    );
  }

  /// 채팅방 삭제 API
  /// POST /api/chat/rooms/delete
  Future<void> deleteChatRoom({required String chatRoomId}) async {
    final String url = '${AppUrls.baseUrl}/api/chat/rooms/delete';

    final Map<String, dynamic> fields = {'chatRoomId': chatRoomId};

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('채팅방 삭제 성공: $chatRoomId');
      },
    );
  }

  /// 채팅방 메시지 조회 API
  /// POST /api/chat/rooms/messages/get
  Future<ChatRoomResponse> getChatMessages({required String chatRoomId, int pageNumber = 0, int pageSize = 30}) async {
    final String url = '${AppUrls.baseUrl}/api/chat/rooms/messages/get';
    late ChatRoomResponse chatRoomResponse;

    final Map<String, dynamic> fields = {
      'chatRoomId': chatRoomId,
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };

    http.Response response = await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        chatRoomResponse = ChatRoomResponse.fromJson(responseData);
        debugPrint('채팅 메시지 조회 성공: ${chatRoomResponse.messages?.content.length ?? 0}개');
      } catch (e) {
        throw Exception('채팅 메시지 파싱 실패: $e');
      }
    } else {
      throw Exception('채팅 메시지 조회 실패: ${response.statusCode}');
    }

    return chatRoomResponse;
  }

  /// 특정 채팅방의 읽음 표시 커서 갱신 API
  /// POST /api/chat/rooms/read-cursor/update
  Future<void> updateChatRoomReadCursor({required String chatRoomId, required bool isEntered}) async {
    final String url = '${AppUrls.baseUrl}/api/chat/rooms/read-cursor/update';

    final Map<String, dynamic> fields = {'chatRoomId': chatRoomId, 'isEntered': isEntered.toString()};

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        isEntered ? debugPrint('채팅방 입장 처리 성공: $chatRoomId') : debugPrint('채팅방 퇴장 처리 성공: $chatRoomId');
      },
    );
  }

  /// 특정 채팅방의 읽음 상태 조회 API
  /// POST /api/chat/rooms/read-status/get
  Future<ChatUserState?> getChatRoomReadStatus({required String chatRoomId}) async {
    final String url = '${AppUrls.baseUrl}/api/chat/rooms/read-status/get';

    final Map<String, dynamic> fields = {'chatRoomId': chatRoomId};

    final http.Response response = await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('상대방 읽음 상태 조회 성공: $chatRoomId');
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final opponentStateJson = responseData['opponentState'];
        if (opponentStateJson != null) {
          return ChatUserState.fromJson(opponentStateJson as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('읽음 상태 파싱 실패: $e');
      }
    }
    return null;
  }

  /// 채팅방 교환 완료 요청 API
  /// POST /api/chat/rooms/trade-completion/request
  Future<void> requestTradeCompletion({required String chatRoomId}) async {
    final String url = '${AppUrls.baseUrl}/api/chat/rooms/trade-completion/request';

    final Map<String, dynamic> fields = {'chatRoomId': chatRoomId};

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('채팅방 교환 완료 요청 성공: $chatRoomId');
      },
    );
  }

  /// 채팅방 교환 완료 요청 거절 API
  /// POST /api/chat/rooms/trade-completion/reject
  Future<void> rejectTradeCompletion({required String chatRoomId}) async {
    final String url = '${AppUrls.baseUrl}/api/chat/rooms/trade-completion/reject';

    final Map<String, dynamic> fields = {'chatRoomId': chatRoomId};

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('채팅방 교환 완료 요청 거절 성공: $chatRoomId');
      },
    );
  }

  /// 채팅방 교환 완료 요청 확인 API
  /// POST /api/chat/rooms/trade-completion/confirm
  Future<void> confirmTradeCompletion({required String chatRoomId}) async {
    final String url = '${AppUrls.baseUrl}/api/chat/rooms/trade-completion/confirm';

    final Map<String, dynamic> fields = {'chatRoomId': chatRoomId};

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('채팅방 교환 완료 요청 확인 성공: $chatRoomId');
      },
    );
  }

  /// 채팅방 교환 완료 요청 취소 API
  /// POST /api/chat/rooms/trade-completion/cancel
  Future<void> cancelTradeCompletionRequest({required String chatRoomId}) async {
    final String url = '${AppUrls.baseUrl}/api/chat/rooms/trade-completion/cancel';

    final Map<String, dynamic> fields = {'chatRoomId': chatRoomId};

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('채팅방 교환 완료 요청 취소 성공: $chatRoomId');
      },
    );
  }
}
