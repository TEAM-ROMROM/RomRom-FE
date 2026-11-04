import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/services/firebase_service.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 알림 권한 1회 안내 판단·요청: 안내 필요 여부(설치당 1회) > 안내 기록 > 시스템 권한 요청 > 허용 시 FCM 토큰 등록
/// 안내 시점: 교환 요청·물품 등록 성공 직후, 거절·닫기 후 자동 재안내 없음
class NotificationPermissionPromptService {
  final Future<AuthorizationStatus> Function() _readAuthorizationStatus;
  final Future<void> Function() _requestSystemPermission;
  final Future<void> Function() _registerFcmToken;
  final bool _isIos;

  // 안내 진행 중 (연속 성공 시 모달 중복 방지)
  bool _isPrompting = false;

  NotificationPermissionPromptService({
    Future<AuthorizationStatus> Function()? readAuthorizationStatus,
    Future<void> Function()? requestSystemPermission,
    Future<void> Function()? registerFcmToken,
    bool? isIos,
  }) : _readAuthorizationStatus = readAuthorizationStatus ?? _readFirebaseAuthorizationStatus,
       _requestSystemPermission = requestSystemPermission ?? FirebaseService().requestNotificationPermission,
       _registerFcmToken = registerFcmToken ?? FirebaseService().handleFcmToken,
       _isIos = isIos ?? Platform.isIOS;

  /// 안내 시작 가능 여부: 진행 중 아님 + 미안내 + 미허용 (iOS 거부 = 시스템 창 다시 못 띄움 > 제외, 조회 실패 > 제외)
  /// 통과 시 진행 중 표시 > [finishPrompt]로 해제
  Future<bool> tryStartPrompt() async {
    if (_isPrompting) return false;
    _isPrompting = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(StorageKeys.notificationPermissionPromptAsked.key) == true) return _stopPrompt();

      final authorizationStatus = await _readAuthorizationStatus();
      if (NotificationPermissionService.isGrantedStatus(authorizationStatus)) return _stopPrompt();
      if (_isIos && authorizationStatus == AuthorizationStatus.denied) return _stopPrompt();

      // 응답과 무관하게 설치당 1회 (거절·닫기 후 재안내 없음)
      await preferences.setBool(StorageKeys.notificationPermissionPromptAsked.key, true);
      return true;
    } catch (error) {
      debugPrint('[notification prompt] check failed : $error');
      return _stopPrompt();
    }
  }

  /// 시스템 권한 요청 > 허용 시 FCM 토큰 등록 (허용 여부 반환)
  Future<bool> requestPermissionAndRegisterToken() async {
    try {
      await _requestSystemPermission();
      final isGranted = NotificationPermissionService.isGrantedStatus(await _readAuthorizationStatus());
      // 허용 직후 토큰 재등록 (권한 전 발급·저장 실패분 보정)
      if (isGranted) await _registerFcmToken();
      return isGranted;
    } catch (error) {
      debugPrint('[notification prompt] request failed : $error');
      return false;
    }
  }

  /// 안내 종료 (성공·실패 공통)
  void finishPrompt() => _isPrompting = false;

  bool _stopPrompt() {
    _isPrompting = false;
    return false;
  }

  static Future<AuthorizationStatus> _readFirebaseAuthorizationStatus() async =>
      (await FirebaseMessaging.instance.getNotificationSettings()).authorizationStatus;
}
