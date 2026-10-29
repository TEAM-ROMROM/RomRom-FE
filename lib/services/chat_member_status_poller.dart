import 'dart:async';

import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

/// 채팅방에서 상대방의 온라인 상태를 주기적으로 폴링하는 싱글톤 클래스
///
/// [HeartbeatManager]가 60초마다 서버에 내 활동 상태를 전송하는 것과 달리,
/// 이 클래스는 상대방의 [Member] 정보를 30초마다 서버에서 가져와
/// [lastActiveAt]을 갱신하는 역할을 한다.
///
/// 온라인 여부 판단은 서버 정책에 따라 클라이언트에서 직접 계산한다.
///   → 현재시각 - lastActiveAt < 90초이면 온라인
///
/// 사용 흐름:
///   1. 채팅방 진입 시 [start] 호출
///   2. [stream]을 구독해 갱신된 [Member]를 수신
///   3. 채팅방 퇴장 시 [stop] 호출
class ChatMemberStatusPoller with WidgetsBindingObserver {
  ChatMemberStatusPoller._() : _fetchMemberProfile = _fetchMemberProfileFromServer;

  /// 폴링 간격 (30초)
  @visibleForTesting
  static const Duration pollInterval = Duration(seconds: 30);

  /// 테스트용 인스턴스: 서버 조회 함수를 대체
  @visibleForTesting
  ChatMemberStatusPoller.forTest({required Future<Member> Function(String memberId) fetchMemberProfile})
    : _fetchMemberProfile = fetchMemberProfile;

  /// 앱 전역에서 하나의 인스턴스만 사용 (싱글톤)
  static final instance = ChatMemberStatusPoller._();

  final Future<Member> Function(String memberId) _fetchMemberProfile;

  static Future<Member> _fetchMemberProfileFromServer(String memberId) async {
    final response = await MemberApi().getMemberProfile(memberId);
    return response.member!;
  }

  Timer? _timer;
  String? _targetMemberId;

  /// 폴링 결과를 방출하는 broadcast 스트림 컨트롤러
  /// broadcast: 여러 위젯이 동시에 구독 가능
  final _controller = StreamController<Member>.broadcast();

  /// 외부에서 구독할 스트림 (새 Member 데이터가 들어올 때마다 방출)
  Stream<Member> get stream => _controller.stream;

  /// 폴링 시작
  ///
  /// 이전에 실행 중인 폴링이 있으면 [stop]으로 먼저 정리 후 재시작
  void start(String memberId) {
    stop(); // 혹시 이전 것 정리
    _targetMemberId = memberId;
    WidgetsBinding.instance.addObserver(this); // 백그라운드 전환 감지

    _fetch(); // 진입 즉시 1회 호출 (첫 폴링 응답 전에 UI 공백 방지)
    _startTimer(); // 이후 30초마다 반복
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => _fetch());
  }

  /// 백그라운드(paused, hidden): 타이머 중단 > 복귀(resumed): 즉시 1회 조회 후 주기 재개
  /// inactive(알림창·권한 팝업 등 일시 가림)는 중단하지 않음
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_targetMemberId == null) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _timer?.cancel();
      _timer = null;
    } else if (state == AppLifecycleState.resumed && _timer == null) {
      _fetch(); // 백그라운드 동안 낡은 상태 즉시 갱신
      _startTimer();
    }
  }

  /// 폴링 중단
  ///
  /// 채팅방 퇴장 또는 [start] 재호출 시 타이머와 타겟 초기화
  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
    _targetMemberId = null;
  }

  /// 상대방 Member 정보를 서버에서 조회 후 스트림에 방출
  ///
  /// 실패 시 조용히 무시하고 다음 주기에 재시도
  /// (온라인 상태 표시 실패는 치명적이지 않으므로 에러를 전파하지 않음)
  Future<void> _fetch() async {
    final targetMemberId = _targetMemberId;
    if (targetMemberId == null) return;
    try {
      final member = await _fetchMemberProfile(targetMemberId);
      if (_controller.isClosed) return;
      _controller.add(member); // 새 Member를 스트림에 방출
    } catch (e) {
      debugPrint('[StatusPoller] failed: $e');
    }
  }

  /// 스트림 컨트롤러 영구 종료
  ///
  /// 앱 종료 등 완전히 더 이상 사용하지 않을 때 호출
  /// [stop]과 달리 스트림 자체를 닫아 재사용 불가 상태가 됨
  void dispose() {
    stop();
    _controller.close();
  }
}
