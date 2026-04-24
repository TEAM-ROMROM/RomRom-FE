import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RuntimeUrlManager {
  static final RuntimeUrlManager _instance = RuntimeUrlManager._internal();
  factory RuntimeUrlManager() => _instance;
  RuntimeUrlManager._internal();

  static const String _prodUrl = 'https://api.romrom.suhsaechan.kr';
  static const String _prefsKey = 'debug_base_url';

  String _currentBaseUrl = _prodUrl;

  final List<void Function(String)> _listeners = [];

  String get baseUrl {
    if (!kDebugMode) return _prodUrl;
    return _currentBaseUrl;
  }

  static String buildPreviewUrl(String prNumber) {
    return 'http://romrom-pr-$prNumber.pr.suhsaechan.kr:8079';
  }

  void addUrlChangeListener(void Function(String) listener) {
    _listeners.add(listener);
  }

  void removeUrlChangeListener(void Function(String) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(String url) {
    for (final listener in List.of(_listeners)) {
      listener(url);
    }
  }

  /// 앱 시작 시 호출 — SharedPreferences에서 저장된 URL 복원
  Future<void> init() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty) {
      _currentBaseUrl = saved;
    }
  }

  Future<void> setBaseUrl(String url) async {
    if (!kDebugMode) return;
    _currentBaseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, url);
    _notifyListeners(url);
  }

  Future<void> resetToDefault() async {
    if (!kDebugMode) return;
    _currentBaseUrl = _prodUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _notifyListeners(_prodUrl);
  }

  bool get isUsingProd => _currentBaseUrl == _prodUrl;
}
