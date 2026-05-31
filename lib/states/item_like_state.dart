import 'package:flutter/foundation.dart';

@immutable
class ItemLikeState {
  final bool isLiked;
  final int likeCount;

  const ItemLikeState({required this.isLiked, required this.likeCount});

  ItemLikeState copyWith({bool? isLiked, int? likeCount}) =>
      ItemLikeState(isLiked: isLiked ?? this.isLiked, likeCount: likeCount ?? this.likeCount);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemLikeState &&
          runtimeType == other.runtimeType &&
          isLiked == other.isLiked &&
          likeCount == other.likeCount;

  @override
  int get hashCode => Object.hash(isLiked, likeCount);

  @override
  String toString() => 'ItemLikeState(isLiked: $isLiked, likeCount: $likeCount)';
}
