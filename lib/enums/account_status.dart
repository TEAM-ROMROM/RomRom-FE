import 'package:json_annotation/json_annotation.dart';

enum AccountStatus {
  @JsonValue('ACTIVE_ACCOUNT')
  activeAccount, // 활성화된 계정

  @JsonValue('DELETE_ACCOUNT')
  deleteAccount, // 탈퇴한 계정

  @JsonValue('TEST_ACCOUNT')
  testAccount, // 테스트 계정
}

extension AccountStatusExtension on AccountStatus {
  String get serverName {
    switch (this) {
      case AccountStatus.activeAccount:
        return 'ACTIVE_ACCOUNT';
      case AccountStatus.deleteAccount:
        return 'DELETE_ACCOUNT';
      case AccountStatus.testAccount:
        return 'TEST_ACCOUNT';
    }
  }

  static AccountStatus fromServerName(String name) {
    return AccountStatus.values.firstWhere((e) => e.serverName == name, orElse: () => AccountStatus.activeAccount);
  }
}
