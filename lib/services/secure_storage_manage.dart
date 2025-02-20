import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

/// storage에 값 저장
Future<void> saveSecureData(Map<String, dynamic> obj) async {
  for (var entry in obj.entries) {
    await storage.write(key: entry.key, value: entry.value.toString());
  }
}

/// storage에 저장된 값 가져오기
Future<String?> getSecureData(String name) async {
  return await storage.read(key: name);
}

/// storage에 저장된 값 지우기
Future<void> deleteSecureData(List name) async {
  for (var entry in name) {
    await storage.delete(key: entry.key);
  }
}
