import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/location_address.dart';

part 'item_request.g.dart';

@JsonSerializable()
class ItemRequest {
  String? memberId;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<String>? itemImageUrls;
  String? itemName;
  String? itemDescription;
  String? itemCategory;
  String? itemCondition;
  List<String>? itemTradeOptions;
  int? itemPrice;
  String? itemId;
  int pageNumber;
  int pageSize;
  double? longitude;
  double? latitude;
  bool? isAiPredictedPrice;
  String? itemStatus;
  double? radiusInMeters;
  int? minPrice;
  int? maxPrice;
  String? startDate;
  String? endDate;
  String? sortField;
  String? sortDirection;
  String? searchKeyword;
  // 홈 피드 전용 (#966): 최근 본 물품 id (최근 본 순), 추천순 섞기 시드 > item_api가 직접 전송
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<String>? recentlySeenItemIds;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int? feedSeed;
  // 등록·수정 전용 (#1004): 거래 희망 위치 행정구역 > item_api가 직접 전송, 서버 물품 address 저장
  @JsonKey(includeFromJson: false, includeToJson: false)
  LocationAddress? tradeLocationAddress;
  // 희망 교환 카테고리 서버 이름 (#1008): null > 미전송(수정 시 서버 기존 값 유지), 빈 목록 > 전부 해제 > item_api가 직접 전송
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<String>? wantedItemCategories;
  // 물품 검색 전용 (#1008): 카테고리 필터 서버 이름, 정렬 서버 이름 > item_api가 직접 전송
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<String>? searchItemCategories;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? searchSortField;

  ItemRequest({
    this.memberId,
    this.itemImageUrls,
    this.itemName,
    this.itemDescription,
    this.itemCategory,
    this.itemCondition,
    this.itemTradeOptions,
    this.itemPrice,
    this.itemId,
    this.pageNumber = 0,
    this.pageSize = 10,
    this.longitude,
    this.latitude,
    this.isAiPredictedPrice,
    this.itemStatus,
    this.radiusInMeters,
    this.minPrice,
    this.maxPrice,
    this.startDate,
    this.endDate,
    this.sortField,
    this.sortDirection,
    this.searchKeyword,
    this.recentlySeenItemIds,
    this.feedSeed,
    this.tradeLocationAddress,
    this.wantedItemCategories,
    this.searchItemCategories,
    this.searchSortField,
  });

  factory ItemRequest.fromJson(Map<String, dynamic> json) => _$ItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ItemRequestToJson(this);
}
