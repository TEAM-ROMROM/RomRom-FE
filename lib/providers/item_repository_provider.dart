import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/services/apis/item_api.dart';

/// ItemRepository 주입용 공유 Provider.
/// 좋아요·내 물건 등 ItemApi 기반 도메인 provider가 공통으로 사용한다.
final itemRepositoryProvider = Provider<ItemRepository>((ref) => ItemRepository(ItemApi()));
