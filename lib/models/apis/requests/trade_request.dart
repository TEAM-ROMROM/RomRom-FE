import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';

part 'trade_request.g.dart';

@JsonSerializable(explicitToJson: true)
class TradeRequest {
  Member? member;
  String? takeItemId;
  String? giveItemId;
  String? tradeRequestHistoryId;
  List<String>? itemTradeOptions;
  int pageNumber;
  int pageSize;
  String? tradeReviewRating;
  List<String>? tradeReviewTags;
  String? reviewComment;
  String? sortField; // BE TradeRequestSortField enum name (CREATED_DATE/PRICE/AI_RECOMMENDED)
  String? sortDirection; // BE Sort.Direction (ASC/DESC)

  TradeRequest({
    this.member,
    this.takeItemId,
    this.giveItemId,
    this.tradeRequestHistoryId,
    this.itemTradeOptions,
    this.pageNumber = 0,
    this.pageSize = 10,
    this.tradeReviewRating,
    this.tradeReviewTags,
    this.reviewComment,
    this.sortField,
    this.sortDirection,
  });

  // API 전송을 위한 setMember 메서드 (백엔드 패턴 따라)
  void setMember(Member member) {
    this.member = member;
  }

  factory TradeRequest.fromJson(Map<String, dynamic> json) => _$TradeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$TradeRequestToJson(this);
}
