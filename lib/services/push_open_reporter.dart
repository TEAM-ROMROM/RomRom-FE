import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:romrom_fe/services/apis/notification_api.dart';
import 'package:romrom_fe/services/deep_link_gate.dart';

/// 캠페인 푸시 열람 보고: campaignId 추출 > 같은 캠페인 1회 > 메인 진입 전이면 보관 > 전송 (실패는 로그만)
/// 메인 진입 전 = 로그인·자동 로그인 전 (인증 없이 보내지 않고 메인 진입 시 보관분 전송)
class PushOpenReporter {
  PushOpenReporter({
    required Future<void> Function(String campaignId) sendPushOpen,
    required bool Function() isMainScreenEntered,
  }) : _sendPushOpen = sendPushOpen,
       _isMainScreenEntered = isMainScreenEntered;

  // 앱 전체 공용 인스턴스 (테스트는 새 인스턴스 생성)
  static final PushOpenReporter instance = PushOpenReporter(
    sendPushOpen: NotificationApi().reportPushOpen,
    isMainScreenEntered: () => DeepLinkGate.instance.isMainScreenEntered,
  );

  // FCM data 캠페인 키 (관리자 캠페인 푸시에만 존재)
  static const String campaignIdDataKey = 'campaignId';

  final Future<void> Function(String campaignId) _sendPushOpen;
  final bool Function() _isMainScreenEntered;

  // 이번 실행에서 처리한 캠페인 (콜드 스타트·백그라운드 탭 중복 수신 대비)
  final Set<String> _handledCampaignIds = {};
  // 메인 진입 전 열린 캠페인 (진입 시 1회 전송)
  final List<String> _pendingCampaignIds = [];

  /// 푸시 열림: 캠페인 푸시만 보고 (기다리지 않음)
  void onPushOpened(Map<String, dynamic> pushData) {
    final campaignId = pushData[campaignIdDataKey];
    if (campaignId is! String || campaignId.isEmpty) return;
    if (!_handledCampaignIds.add(campaignId)) return;

    if (!_isMainScreenEntered()) {
      _pendingCampaignIds.add(campaignId);
      debugPrint('[push open] queued until main screen : campaignId=$campaignId');
      return;
    }
    unawaited(_sendSafely(campaignId));
  }

  /// 메인 화면 진입: 보관분 전송 (1회)
  void onMainScreenEntered() {
    if (_pendingCampaignIds.isEmpty) return;
    final campaignIdsToSend = List<String>.of(_pendingCampaignIds);
    _pendingCampaignIds.clear();
    for (final campaignId in campaignIdsToSend) {
      unawaited(_sendSafely(campaignId));
    }
  }

  /// 전송 1건 (실패는 로그만, 재시도 없음)
  Future<void> _sendSafely(String campaignId) async {
    try {
      await _sendPushOpen(campaignId);
    } catch (error) {
      debugPrint('[push open] report failed : campaignId=$campaignId, $error');
    }
  }
}
