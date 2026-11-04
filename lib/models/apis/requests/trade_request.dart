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
  int? extraChargeAmount; // 추가금 (원, EXTRA_CHARGE 선택 시만, 미입력 null)
  String? requestMessage; // 한 줄 메시지 (최대 100자, 미입력 null)
  bool? includeRejected; // 보낸 요청 목록에 거절 건 포함 여부
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
    this.extraChargeAmount,
    this.requestMessage,
    this.includeRejected,
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
