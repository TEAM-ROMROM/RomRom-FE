import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// 채팅방별 STOMP 토픽 구독 묶음: 참조 카운트, 브로드캐스트 스트림, STOMP 구독 핸들, JSON 본문 > 모델 변환
/// 같은 방을 여러 화면이 구독해도 STOMP 구독 1개 유지 (참조 0 > 실제 해제)
class ChatTopicSubscriptionRegistry<T> {
  // 채팅방 ID > STOMP destination (예: /sub/chat.read.{chatRoomId})
  final String Function(String chatRoomId) destinationOf;
  // JSON 본문 > 모델
  final T Function(Map<String, dynamic> json) parseBody;
  // 로그 접두 이름 (예: read event)
  final String topicLabel;

  final Map<String, StreamController<T>> _controllerByChatRoomId = {};
  final Map<String, StompUnsubscribe> _stompUnsubscribeByChatRoomId = {};
  final Map<String, int> _referenceCountByChatRoomId = {};

  ChatTopicSubscriptionRegistry({required this.destinationOf, required this.parseBody, required this.topicLabel});

  /// 구독한 채팅방 ID 목록 (재연결 시 재구독 대상)
  Iterable<String> get subscribedChatRoomIds => _controllerByChatRoomId.keys;

  /// 구독: 참조 +1 > 기존 스트림 재사용 또는 새 스트림 생성 > 연결 상태면 STOMP 구독
  Stream<T> subscribe(String chatRoomId, {required StompClient? stompClient, required bool isConnected}) {
    _referenceCountByChatRoomId[chatRoomId] = (_referenceCountByChatRoomId[chatRoomId] ?? 0) + 1;
    debugPrint(
      '[WebSocket] Subscribe to $topicLabel $chatRoomId (refCount: ${_referenceCountByChatRoomId[chatRoomId]})',
    );

    final existingController = _controllerByChatRoomId[chatRoomId];
    if (existingController != null) return existingController.stream;

    final controller = StreamController<T>.broadcast();
    _controllerByChatRoomId[chatRoomId] = controller;
    if (isConnected && stompClient != null) subscribeOnStomp(chatRoomId, stompClient);
    return controller.stream;
  }

  /// 실제 STOMP 구독 실행 (최초 구독·재연결 공통)
  void subscribeOnStomp(String chatRoomId, StompClient stompClient) {
    final destination = destinationOf(chatRoomId);
    debugPrint('[WebSocket] ✅ Subscribing to: $destination');
    _stompUnsubscribeByChatRoomId[chatRoomId] = stompClient.subscribe(
      destination: destination,
      callback: (StompFrame frame) => handleFrameBody(chatRoomId, frame.body),
    );
  }

  /// 프레임 본문 > 모델 > 해당 방 스트림 전달 (본문 없음·파싱 실패 > 무시)
  @visibleForTesting
  void handleFrameBody(String chatRoomId, String? body) {
    if (body == null) return;
    try {
      final parsed = parseBody(jsonDecode(body) as Map<String, dynamic>);
      _controllerByChatRoomId[chatRoomId]?.add(parsed);
    } catch (error) {
      debugPrint('[WebSocket] $topicLabel parse failed: $error');
    }
  }

  /// 구독 해제: 참조 -1 > 0이면 STOMP 해제·스트림 닫기
  void unsubscribe(String chatRoomId) {
    final currentCount = _referenceCountByChatRoomId[chatRoomId] ?? 0;
    if (currentCount <= 0) return;

    final newCount = currentCount - 1;
    debugPrint('[WebSocket] Unsubscribe from $topicLabel $chatRoomId (refCount: $newCount)');
    if (newCount > 0) {
      _referenceCountByChatRoomId[chatRoomId] = newCount;
      return;
    }
    _referenceCountByChatRoomId.remove(chatRoomId);
    try {
      _stompUnsubscribeByChatRoomId.remove(chatRoomId)?.call();
    } catch (error) {
      debugPrint('[WebSocket] $topicLabel unsubscribe error: $error');
    }
    _controllerByChatRoomId.remove(chatRoomId)?.close();
    debugPrint('[WebSocket] ✅ Fully unsubscribed from $topicLabel $chatRoomId');
  }

  /// 연결 해제 시 전부 정리: STOMP 구독 해제 > 스트림 닫기 > 참조 카운트 초기화
  Future<void> closeAll() async {
    for (final stompUnsubscribe in _stompUnsubscribeByChatRoomId.values) {
      stompUnsubscribe();
    }
    _stompUnsubscribeByChatRoomId.clear();
    for (final controller in _controllerByChatRoomId.values) {
      await controller.close();
    }
    _controllerByChatRoomId.clear();
    _referenceCountByChatRoomId.clear();
  }
}
