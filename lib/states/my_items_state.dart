import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';

@immutable
class MyItemsState {
  final List<Item> available; // 판매중
  final List<Item> exchanged; // 교환완료

  const MyItemsState({this.available = const [], this.exchanged = const []});

  bool get hasAvailable => available.isNotEmpty;

  MyItemsState copyWith({List<Item>? available, List<Item>? exchanged}) =>
      MyItemsState(available: available ?? this.available, exchanged: exchanged ?? this.exchanged);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyItemsState &&
          runtimeType == other.runtimeType &&
          listEquals(available, other.available) &&
          listEquals(exchanged, other.exchanged);

  @override
  int get hashCode => Object.hash(Object.hashAll(available), Object.hashAll(exchanged));

  @override
  String toString() => 'MyItemsState(available: ${available.length}, exchanged: ${exchanged.length})';
}
