// lib/models/apis/responses/item_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/item_image.dart';
import 'package:romrom_fe/models/apis/responses/item_detail.dart';

part 'item_response.g.dart';

@JsonSerializable()
class ItemResponse {
  final Item? item;
  final List<ItemImage>? itemImages;
  final List<String>? itemCustomTags;
  final String? likeStatus;
  final int? likeCount;
  final PageItemDetail? itemDetailPage;

  ItemResponse({
    this.item,
    this.itemImages,
    this.itemCustomTags,
    this.likeStatus,
    this.likeCount,
    this.itemDetailPage,
  });

  factory ItemResponse.fromJson(Map<String, dynamic> json) =>
      _$ItemResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ItemResponseToJson(this);
}

@JsonSerializable()
class PageItemDetail {
  final List<ItemDetail>? content;
  final int? totalPages;
  final int? totalElements;
  final bool? last;
  final int? size;
  final int? number;
  final int? numberOfElements;
  final bool? first;
  final bool? empty;

  PageItemDetail({
    this.content,
    this.totalPages,
    this.totalElements,
    this.last,
    this.size,
    this.number,
    this.numberOfElements,
    this.first,
    this.empty,
  });

  factory PageItemDetail.fromJson(Map<String, dynamic> json) =>
      _$PageItemDetailFromJson(json);

  Map<String, dynamic> toJson() => _$PageItemDetailToJson(this);
}
