import 'dart:async';

import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

/// 채팅 상대 접속 상태 폴링 싱글톤: 상대 [Member] 30초 주기 조회, 화면별 결과 스트림([streamOf]), 백그라운드 중단
/// 화면 소유자별 [start]/[stop] > 맨 위(마지막 start) 화면 상대만 폴링 > 위 화면 종료 시 아래 화면 상대 재개
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

  // 폴링 요청 화면 순서 (마지막 = 맨 위 화면 > 폴링 대상)
  final List<({Object owner, String memberId})> _pollingRequests = [];
  bool _isObservingLifecycle = false;

  String? get _targetMemberId => _pollingRequests.isEmpty ? null : _pollingRequests.last.memberId;

  /// 폴링 결과 broadcast 스트림 컨트롤러 (조회한 회원 ID 포함, 여러 화면 동시 구독)
  final _controller = StreamController<({String memberId, Member member})>.broadcast();

  /// [memberId] 조회 결과만 방출하는 스트림 (응답 memberId 누락과 무관하게 요청 ID로 판정)
  Stream<Member> streamOf(String memberId) =>
      _controller.stream.where((result) => result.memberId == memberId).map((result) => result.member);

  /// 폴링 시작: 같은 소유자 이전 요청 교체 > 맨 위로 등록 > 즉시 1회 조회 후 주기 반복
  void start(String memberId, {required Object owner}) {
    _pollingRequests.removeWhere((request) => identical(request.owner, owner));
    _pollingRequests.add((owner: owner, memberId: memberId));
    _activateTopRequest();
  }

  /// 소유자 폴링 중단: 맨 위였으면 아래 화면 상대로 재개, 남은 요청 없으면 정지
  void stop({required Object owner}) {
    final isTopRequest = _pollingRequests.isNotEmpty && identical(_pollingRequests.last.owner, owner);
    _pollingRequests.removeWhere((request) => identical(request.owner, owner));
    if (!isTopRequest) return;
    if (_pollingRequests.isEmpty) {
      _halt();
    } else {
      _activateTopRequest(); // 아래 화면 상대 즉시 갱신 후 주기 재개
    }
  }

  /// 전체 폴링 중단 (세션 종료)
  void stopAll() {
    _pollingRequests.clear();
    _halt();
  }

  /// 맨 위 요청 폴링 시작 (백그라운드 전환 감지 등록 포함)
  void _activateTopRequest() {
    if (!_isObservingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _isObservingLifecycle = true;
    }
    _fetch(); // 진입 즉시 1회 호출 (첫 폴링 응답 전에 UI 공백 방지)
    _startTimer(); // 이후 30초마다 반복
  }

  /// 타이머·감지 해제
  void _halt() {
    if (_isObservingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _isObservingLifecycle = false;
    }
    _timer?.cancel();
    _timer = null;
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
      _controller.add((memberId: targetMemberId, member: member)); // 요청 회원 ID와 함께 방출
    } catch (e) {
      debugPrint('[StatusPoller] failed: $e');
    }
  }

  /// 스트림 컨트롤러 영구 종료
  ///
  /// 앱 종료 등 완전히 더 이상 사용하지 않을 때 호출
  /// [stopAll]과 달리 스트림 자체를 닫아 재사용 불가 상태가 됨
  void dispose() {
    stopAll();
    _controller.close();
  }
}
