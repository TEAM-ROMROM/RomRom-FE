// lib/models/apis/responses/item_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';

part 'item_response.g.dart';

///
/// {
///   "item": null | { ...ItemDetail },
///   "itemPage": {
///     "content": [ { ...ItemDetail }, ... ],
///     "page": { "size": 2, "number": 0, "totalElements": 5, "totalPages": 3 }
///   },
///   "isLiked": null | true | false
/// }
@JsonSerializable()
class ItemResponse {
  final Item? item;
  final ItemPage? itemPage;
  final bool? isLiked;

  ItemResponse({
    this.item,
    this.itemPage,
    this.isLiked,
  });

  factory ItemResponse.fromJson(Map<String, dynamic> json) =>
      _$ItemResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ItemResponseToJson(this);
}

@JsonSerializable()
class ItemPage {
  final List<Item> content;
  final Page page;

  ItemPage({
    required this.content,
    required this.page,
  });

  factory ItemPage.fromJson(Map<String, dynamic> json) =>
      _$ItemPageFromJson(json);

  Map<String, dynamic> toJson() => _$ItemPageToJson(this);
}

@JsonSerializable()
class Page {
  final int size;
  final int number;
  final int totalElements;
  final int totalPages;

  const Page({
    required this.size,
    required this.number,
    required this.totalElements,
    required this.totalPages,
  });

  factory Page.fromJson(Map<String, dynamic> json) => _$PageFromJson(json);

  Map<String, dynamic> toJson() => _$PageToJson(this);
}
