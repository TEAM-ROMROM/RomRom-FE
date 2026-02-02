import 'package:json_annotation/json_annotation.dart';

part 'naver_address_response.g.dart';

/// 네이버 주소 API 응답 모델
/// 좌표(경도, 위도)로 주소 정보를 조회하는 Reverse Geocoding API의 응답을 담는 모델
/// 공식문서 : https://api.ncloud-docs.com/docs/ai-naver-mapsreversegeocoding-gc
@JsonSerializable()
class NaverAddressResponse {
  /// API 호출 상태 정보
  final Status status;

  /// 검색 결과 목록
  final List<Result> results;

  NaverAddressResponse({required this.status, required this.results});

  factory NaverAddressResponse.fromJson(Map<String, dynamic> json) => _$NaverAddressResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NaverAddressResponseToJson(this);
}

@JsonSerializable()
/// API 응답 상태 정보
class Status {
  /// 응답 코드 (0: 정상)
  final int code;

  /// 응답 상태명 (ok: 정상)
  final String name;

  /// 응답 메시지
  final String message;

  Status({required this.code, required this.name, required this.message});

  factory Status.fromJson(Map<String, dynamic> json) => _$StatusFromJson(json);
  Map<String, dynamic> toJson() => _$StatusToJson(this);
}

@JsonSerializable()
/// 검색 결과 항목
class Result {
  /// 검색 결과 명칭
  final String name;

  /// 코드 정보 (행정동/법정동 코드)
  final Code code;

  /// 지역 정보 (행정구역 정보)
  final Region region;

  /// 지번/도로명 주소 상세 정보 (검색 결과에 따라 없을 수 있음)
  final Land? land;

  Result({required this.name, required this.code, required this.region, this.land});

  factory Result.fromJson(Map<String, dynamic> json) => _$ResultFromJson(json);
  Map<String, dynamic> toJson() => _$ResultToJson(this);
}

@JsonSerializable()
/// 지역 코드 정보
class Code {
  /// 코드 ID
  final String id;

  /// 코드 타입 (법정동 코드: L, 행정동 코드: A)
  final String type;

  /// 매핑 ID
  final String mappingId;

  Code({required this.id, required this.type, required this.mappingId});

  factory Code.fromJson(Map<String, dynamic> json) => _$CodeFromJson(json);
  Map<String, dynamic> toJson() => _$CodeToJson(this);
}

@JsonSerializable()
/// 지역 정보 (행정구역 계층 구조)
class Region {
  /// 국가 정보
  final Area area0;

  /// 시/도 정보
  final Area area1;

  /// 시/군/구 정보
  final Area area2;

  /// 읍/면/동 정보
  final Area area3;

  /// 리 정보
  final Area area4;

  Region({required this.area0, required this.area1, required this.area2, required this.area3, required this.area4});

  factory Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);
  Map<String, dynamic> toJson() => _$RegionToJson(this);
}

@JsonSerializable()
/// 행정구역 단위 정보
class Area {
  /// 행정구역 이름
  final String name;

  /// 행정구역 좌표 정보
  final Coords coords;

  /// 행정구역 별칭 (있는 경우만)
  final String? alias;

  Area({required this.name, required this.coords, this.alias});

  factory Area.fromJson(Map<String, dynamic> json) => _$AreaFromJson(json);
  Map<String, dynamic> toJson() => _$AreaToJson(this);
}

@JsonSerializable()
/// 좌표 정보
class Coords {
  /// 중심점 좌표
  final NaverCenter center;

  Coords({required this.center});

  factory Coords.fromJson(Map<String, dynamic> json) => _$CoordsFromJson(json);
  Map<String, dynamic> toJson() => _$CoordsToJson(this);
}

@JsonSerializable()
/// 중심점 좌표 정보
class NaverCenter {
  /// 좌표계 (EPSG:4326 - WGS84 경위도 좌표계)
  final String crs;

  /// 경도 (longitude)
  final double x;

  /// 위도 (latitude)
  final double y;

  NaverCenter({required this.crs, required this.x, required this.y});

  factory NaverCenter.fromJson(Map<String, dynamic> json) => _$NaverCenterFromJson(json);
  Map<String, dynamic> toJson() => _$NaverCenterToJson(this);
}

@JsonSerializable()
/// 지번/도로명 주소 상세 정보
class Land {
  /// 주소 타입 (1: 지번 주소, 2: 도로명 주소)
  final String? type;

  /// 지번 주소일 경우 번지, 도로명 주소일 경우 건물 번호
  final String? number1;

  /// 지번 주소일 경우 부번지, 도로명 주소일 경우 건물 번호 뒷자리
  final String? number2;

  /// 추가 정보 0 (도로명 주소인 경우 도로명)
  final Addition? addition0;

  /// 추가 정보 1 (행정동 정보)
  final Addition? addition1;

  /// 추가 정보 2 (공동 주택 정보 등)
  final Addition? addition2;

  /// 추가 정보 3
  final Addition? addition3;

  /// 추가 정보 4
  final Addition? addition4;

  /// 명칭
  final String? name;

  /// 좌표 정보
  final Coords? coords;

  Land({
    this.type,
    this.number1,
    this.number2,
    this.addition0,
    this.addition1,
    this.addition2,
    this.addition3,
    this.addition4,
    this.name,
    this.coords,
  });

  factory Land.fromJson(Map<String, dynamic> json) => _$LandFromJson(json);
  Map<String, dynamic> toJson() => _$LandToJson(this);
}

@JsonSerializable()
/// 추가 주소 정보
class Addition {
  /// 추가 정보 타입
  /// 'labelName': 지번/도로명 주소 개별 명칭
  /// 'adminDong': 행정동
  /// 'buildingName': 건물명
  /// 'jibunAddress': 지번 주소
  /// 'roadName': 도로명
  final String type;

  /// 추가 정보 값
  final String value;

  Addition({required this.type, required this.value});

  factory Addition.fromJson(Map<String, dynamic> json) => _$AdditionFromJson(json);
  Map<String, dynamic> toJson() => _$AdditionToJson(this);
}
