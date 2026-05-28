// lib/providers/chat_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/chat_repository.dart';
import 'package:romrom_fe/services/apis/chat_api.dart';

/// ChatRepository 주입용 공유 Provider.
final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository(ChatApi()));
