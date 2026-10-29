// lib/providers/trade_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';

/// TradeRepository 주입용 공유 Provider.
final tradeRepositoryProvider = Provider<TradeRepository>((ref) => TradeRepository(TradeApi()));
