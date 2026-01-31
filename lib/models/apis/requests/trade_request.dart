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

  TradeRequest({
    this.member,
    this.takeItemId,
    this.giveItemId,
    this.tradeRequestHistoryId,
    this.itemTradeOptions,
    this.pageNumber = 0,
    this.pageSize = 10,
  });

  // API 전송을 위한 setMember 메서드 (백엔드 패턴 따라)
  void setMember(Member member) {
    this.member = member;
  }

  factory TradeRequest.fromJson(Map<String, dynamic> json) => _$TradeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$TradeRequestToJson(this);
}
