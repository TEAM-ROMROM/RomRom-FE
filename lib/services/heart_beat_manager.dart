import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

/// lifecycle=resumed/paused로 포그라운드 전환 감지되는지
/// sending 로그가 60초마다 찍히는지
/// throttled가 뜨면 60초 제한 때문에 스킵된 것
/// failed면 네트워크/인증 문제(토큰 만료 등)라 MemberApi().heartbeat() 쪽 에러를 보면 됨
class HeartbeatManager with WidgetsBindingObserver {
  HeartbeatManager._();
  static final HeartbeatManager instance = HeartbeatManager._();

  Timer? _timer;
  bool _started = false;
  bool _inFlight = false;
  DateTime? _lastSentAt;

  /// 서버 정책: 60초에 1번 업데이트 가능
  final Duration interval = const Duration(seconds: 60);

  void start() {
    if (_started) {
      debugPrint('[HB] start() ignored: already started');
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    // 앱 시작 시점이 이미 resumed일 수 있어 1회 쏴줌
    debugPrint('[HB] started. interval=${interval.inSeconds}s');
    _send(immediate: true, reason: 'start');
    _startTimer();
  }

  void stop() {
    if (!_started) {
      debugPrint('[HB] stop() ignored: not started');
      return;
    }
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;

    debugPrint('[HB] stopped');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[HB] lifecycle=$state');

    if (!_started) return;

    if (state == AppLifecycleState.resumed) {
      // 포그라운드 복귀 즉시 1회
      _send(immediate: true, reason: 'resumed');
      _startTimer();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // 백그라운드에서는 중단
      _timer?.cancel();
      _timer = null;
      debugPrint('[HB] timer stopped (background)');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _send(reason: 'timer'));
    debugPrint('[HB] timer started');
  }

  Future<void> _send({bool immediate = false, required String reason}) async {
    if (!_started) {
      debugPrint('[HB] skip: not started');
      return;
    }
    if (_inFlight) {
      debugPrint('[HB] skip: inFlight=true (reason=$reason)');
      return;
    }

    final now = DateTime.now();

    if (!immediate && _lastSentAt != null) {
      final diff = now.difference(_lastSentAt!);
      if (diff < interval) {
        // 60초 쓰로틀
        debugPrint('[HB] skip: throttled diff=${diff.inSeconds}s < ${interval.inSeconds}s (reason=$reason)');
        return;
      }
    }

    _inFlight = true;
    debugPrint('[HB] -> sending (reason=$reason) at=$now lastSent=$_lastSentAt');

    try {
      // MemberApi 안의 heartbeat() 그대로 사용
      await MemberApi().heartbeat();
      _lastSentAt = DateTime.now();
      debugPrint('[HB] <- success at=$_lastSentAt');
    } catch (e, st) {
      // 실패는 무시하고 다음 주기에 재시도 (필요하면 backoff 추가)
      debugPrint('[HB] !! failed: $e');
      debugPrint('$st');
    } finally {
      _inFlight = false;
    }
  }
}
