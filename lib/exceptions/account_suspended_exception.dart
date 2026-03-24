/// 정지된 계정으로 로그인 시도 시 발생하는 예외
class AccountSuspendedException implements Exception {
  final String suspendReason;
  final String suspendedUntil;

  AccountSuspendedException({required this.suspendReason, required this.suspendedUntil});

  @override
  String toString() => 'AccountSuspendedException: reason=$suspendReason, until=$suspendedUntil';
}
