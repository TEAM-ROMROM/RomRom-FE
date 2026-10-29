import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/services/item_address_resolver.dart';

/// 물품 주소 변환기 주입 (테스트에서 override)
final itemAddressResolverProvider = Provider<ItemAddressResolver>((ref) => ItemAddressResolver());
