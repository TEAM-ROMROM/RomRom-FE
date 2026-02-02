import 'package:json_annotation/json_annotation.dart';

part 'api_page.g.dart';

// 공용 Page 모델
@JsonSerializable()
class ApiPage {
  final int size;
  final int number;
  final int totalElements;
  final int totalPages;

  const ApiPage({required this.size, required this.number, required this.totalElements, required this.totalPages});

  factory ApiPage.fromJson(Map<String, dynamic> json) => _$ApiPageFromJson(json);
  Map<String, dynamic> toJson() => _$ApiPageToJson(this);
}
