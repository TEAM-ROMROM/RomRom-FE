// lib/models/apis/responses/item_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/api_page.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';

part 'item_response.g.dart';

@JsonSerializable()
class ItemResponse {
  final Item? item;
  final ItemPage? itemPage;
  final bool? isLiked;

  ItemResponse({this.item, this.itemPage, this.isLiked});

  factory ItemResponse.fromJson(Map<String, dynamic> json) =>
      _$ItemResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ItemResponseToJson(this);
}

@JsonSerializable()
class ItemPage {
  @JsonKey(fromJson: _itemsFromJson, toJson: _itemsToJson)
  final List<Item> content;

  @JsonKey(name: 'page')
  final ApiPage page;

  ItemPage({required this.content, required this.page});

  factory ItemPage.fromJson(Map<String, dynamic> json) =>
      _$ItemPageFromJson(json);
  Map<String, dynamic> toJson() => _$ItemPageToJson(this);
}

// ----- 안전 파서 -----
List<Item> _itemsFromJson(Object? value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().map(Item.fromJson).toList();
  }
  return const <Item>[];
}

Object _itemsToJson(List<Item> items) => items.map((e) => e.toJson()).toList();
