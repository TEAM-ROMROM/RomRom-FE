import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

/// 현재 로그인한 회원 정보를 관리
class MemberManagerService {
  static final MemberManagerService _instance = MemberManagerService._internal();
  factory MemberManagerService() => _instance;
  MemberManagerService._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _memberIdKey = 'current_member_id';
  static const String _nicknameKey = 'current_nickname';
  static const String _emailKey = 'current_email';
  static const String _profileUrlKey = 'current_profile_url';

  // 캐시된 회원 정보
  Member? _cachedMember;
  String? _cachedMemberId;
  
  // 로딩 상태 관리
  bool _isLoading = false;
  bool _isInitialized = false;

  // 리스너들 (상태 변화 감지용)
  final List<VoidCallback> _listeners = [];

  /// 상태 변화 리스너 추가
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// 상태 변화 리스너 제거
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// 리스너들에게 상태 변화 알림
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 현재 회원 ID 가져오기 (캐시 우선, 없으면 저장소에서)
  Future<String?> getCurrentMemberId() async {
    if (_cachedMemberId != null) {
      return _cachedMemberId;
    }

    _cachedMemberId = await _storage.read(key: _memberIdKey);
    return _cachedMemberId;
  }

  /// 현재 회원 정보 가져오기 (캐시 우선, 없으면 API 호출)
  Future<Member?> getCurrentMember({bool forceRefresh = false}) async {
    // 이미 로딩 중이면 대기
    if (_isLoading && !forceRefresh) {
      return _cachedMember;
    }

    // 캐시된 데이터가 있고 강제 새로고침이 아니면 캐시 반환
    if (_cachedMember != null && !forceRefresh) {
      return _cachedMember;
    }

    return await _fetchMemberInfo();
  }

  /// 서버에서 회원 정보 가져오기
  Future<Member?> _fetchMemberInfo() async {
    if (_isLoading) return _cachedMember;

    _isLoading = true;
    _notifyListeners();

    try {
      final memberApi = MemberApi();
      final response = await memberApi.getMemberInfo();
      
      if (response.member != null) {
        await _saveMemberInfo(response.member!);
        _cachedMember = response.member;
        _cachedMemberId = response.member!.memberId;
        _isInitialized = true;
      }

      return _cachedMember;
    } catch (e) {
      debugPrint('회원 정보 조회 실패: $e');
      return null;
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  /// 회원 정보를 Secure Storage에 저장
  Future<void> _saveMemberInfo(Member member) async {
    await Future.wait([
      _storage.write(key: _memberIdKey, value: member.memberId ?? ''),
      _storage.write(key: _nicknameKey, value: member.nickname ?? ''),
      _storage.write(key: _emailKey, value: member.email ?? ''),
      _storage.write(key: _profileUrlKey, value: member.profileUrl ?? ''),
    ]);
  }

  /// 로그인 시 회원 정보 저장 (로그인 플로우에서 호출)
  Future<void> saveMemberInfo(Member member) async {
    await _saveMemberInfo(member);
    _cachedMember = member;
    _cachedMemberId = member.memberId;
    _isInitialized = true;
    _notifyListeners();
  }

  /// 두 회원 ID가 같은지 비교하는 헬퍼 메서드
  Future<bool> isSameMember(String? targetMemberId) async {
    if (targetMemberId == null || targetMemberId.isEmpty) {
      return false;
    }

    final currentMemberId = await getCurrentMemberId();
    return currentMemberId != null && currentMemberId == targetMemberId;
  }

  /// 현재 로그인한 회원이 작성자인지 확인 (더 명확한 네이밍)
  Future<bool> isAuthor(String? authorMemberId) async {
    return await isSameMember(authorMemberId);
  }

  /// 로그아웃 시 캐시 및 저장된 정보 삭제
  Future<void> clearMemberInfo() async {
    await Future.wait([
      _storage.delete(key: _memberIdKey),
      _storage.delete(key: _nicknameKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _profileUrlKey),
    ]);

    _cachedMember = null;
    _cachedMemberId = null;
    _isInitialized = false;
    _notifyListeners();
  }

  /// 현재 로딩 상태
  bool get isLoading => _isLoading;

  /// 초기화 여부
  bool get isInitialized => _isInitialized;

  /// 캐시된 회원 정보 (즉시 접근용)
  Member? get cachedMember => _cachedMember;

  /// 캐시된 회원 ID (즉시 접근용)
  String? get cachedMemberId => _cachedMemberId;
}

/// 회원 정보 관리를 위한 정적 메서드 제공 클래스
/// TokenManager와 동일한 패턴으로 구현
class MemberManager {
  static final MemberManagerService _service = MemberManagerService();
  
  /// 현재 회원 정보 가져오기
  static Future<Member?> getCurrentMember({bool forceRefresh = false}) async {
    return await _service.getCurrentMember(forceRefresh: forceRefresh);
  }

  /// 현재 회원 ID 가져오기
  static Future<String?> getCurrentMemberId() async {
    return await _service.getCurrentMemberId();
  }

  /// 두 회원 ID가 동일한지 확인
  static Future<bool> hasSameMemberId(String? targetMemberId) async {
    return await _service.isSameMember(targetMemberId);
  }

  /// 현재 회원이 지정된 회원과 동일한지 확인 (작성자 체크용)
  static Future<bool> isCurrentMember(String? memberId) async {
    return await _service.isSameMember(memberId);
  }

  /// 회원 정보 저장 (로그인 시 호출)
  static Future<void> saveMemberInfo(Member member) async {
    return await _service.saveMemberInfo(member);
  }

  /// 회원 정보 삭제 (로그아웃 시 호출)
  static Future<void> clearMemberInfo() async {
    return await _service.clearMemberInfo();
  }

  /// 즉시 접근 가능한 캐시된 정보
  static Member? get cachedMember => _service.cachedMember;
  static String? get cachedMemberId => _service.cachedMemberId;
  static bool get isLoading => _service.isLoading;
  static bool get isInitialized => _service.isInitialized;

  /// 상태 변화 리스너
  static void addListener(VoidCallback listener) => _service.addListener(listener);
  static void removeListener(VoidCallback listener) => _service.removeListener(listener);
}