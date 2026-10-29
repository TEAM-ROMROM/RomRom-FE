import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/home_feed_repository.dart';
import 'package:romrom_fe/services/apis/item_api.dart';

/// HomeFeedRepository 주입용 Provider.
/// 테스트에서 override하여 mock을 주입한다.
final homeFeedRepositoryProvider = Provider<HomeFeedRepository>((ref) => HomeFeedRepository(ItemApi()));
