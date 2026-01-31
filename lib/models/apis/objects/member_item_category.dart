import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';

part 'member_item_category.g.dart';

@JsonSerializable(explicitToJson: true)
class MemberItemCategory extends BaseEntity {
  final String? memberItemCategoryId;
  final String? itemCategory;

  MemberItemCategory({this.memberItemCategoryId, this.itemCategory, super.createdDate, super.updatedDate});

  factory MemberItemCategory.fromJson(Map<String, dynamic> json) => _$MemberItemCategoryFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MemberItemCategoryToJson(this);
}
