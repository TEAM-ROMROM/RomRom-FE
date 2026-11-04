import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/models/location_verification_record.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GPS 동네 인증 기록 로컬 저장소: 기록 읽기·저장·삭제, 현재 회원 ID
/// 기록 1건만 보관 (회원 ID 포함 > 다른 계정 로그인 시 미인증 판정), 로그아웃 시 UserInfo 정리에서 삭제
class LocationVerificationRepository {
  final Future<String?> Function() _readCurrentMemberId;

  LocationVerificationRepository({Future<String?> Function()? readCurrentMemberId})
    : _readCurrentMemberId = readCurrentMemberId ?? UserInfo().getCurrentMemberId;

  /// 현재 로그인 회원 ID (비로그인·읽기 실패 > null)
  Future<String?> readCurrentMemberId() async {
    try {
      return await _readCurrentMemberId();
    } catch (error) {
      debugPrint('[location verification] member id read failed : $error');
      return null;
    }
  }

  /// 저장된 인증 기록 (없음·형식 오류·읽기 실패 > null)
  Future<LocationVerificationRecord?> loadRecord() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encodedRecord = preferences.getString(StorageKeys.locationVerificationRecord.key);
      if (encodedRecord == null) return null;
      final decodedRecord = jsonDecode(encodedRecord);
      if (decodedRecord is! Map<String, dynamic>) return null;
      return LocationVerificationRecord.tryFromJson(decodedRecord);
    } catch (error) {
      debugPrint('[location verification] record load failed : $error');
      return null;
    }
  }

  /// 인증 기록 저장 (이전 기록 교체) + 위치 저장 완료 플래그 동기화 (실패 시 예외 전달)
  Future<void> saveRecord(LocationVerificationRecord record) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(StorageKeys.locationVerificationRecord.key, jsonEncode(record.toJson()));
    // 기존 위치 저장 플래그 사용처(코치마크·회원 정보 저장) 유지
    UserInfo().isMemberLocationSaved = true;
    await preferences.setBool('isMemberLocationSaved', true);
  }

  /// 인증 기록 삭제
  Future<void> clearRecord() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(StorageKeys.locationVerificationRecord.key);
  }
}
