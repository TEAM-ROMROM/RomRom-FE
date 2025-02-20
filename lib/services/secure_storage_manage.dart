import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

/// storage에 값 저장
Future<void> saveSecureValueByKey(Map<String, dynamic> obj) async {
  for (var entry in obj.entries) {
    await storage.write(key: entry.key, value: entry.value.toString());
  }
}

/// storage에 저장된 값 가져오기
Future<String?> getSecureValueByKey(String name) async {
  return await storage.read(key: name);
}

/// storage에 저장된 값 지우기
Future<void> deleteSecureDataByKeys(List keys) async {
  for (var entry in keys) {
    await storage.delete(key: entry.key);
  }
}
