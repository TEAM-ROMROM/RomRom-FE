// lib/providers/member_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/member_repository.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

/// MemberRepository 주입용 공유 Provider.
/// 본인 프로필 도메인 provider가 공통으로 사용한다.
final memberRepositoryProvider = Provider<MemberRepository>((ref) => MemberRepository(MemberApi()));
