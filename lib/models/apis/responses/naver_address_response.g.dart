// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'naver_address_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NaverAddressResponse _$NaverAddressResponseFromJson(
        Map<String, dynamic> json) =>
    NaverAddressResponse(
      status: Status.fromJson(json['status'] as Map<String, dynamic>),
      results: (json['results'] as List<dynamic>)
          .map((e) => Result.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NaverAddressResponseToJson(
        NaverAddressResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'results': instance.results,
    };

Status _$StatusFromJson(Map<String, dynamic> json) => Status(
      code: (json['code'] as num).toInt(),
      name: json['name'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$StatusToJson(Status instance) => <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'message': instance.message,
    };

Result _$ResultFromJson(Map<String, dynamic> json) => Result(
      name: json['name'] as String,
      code: Code.fromJson(json['code'] as Map<String, dynamic>),
      region: Region.fromJson(json['region'] as Map<String, dynamic>),
      land: json['land'] == null
          ? null
          : Land.fromJson(json['land'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ResultToJson(Result instance) => <String, dynamic>{
      'name': instance.name,
      'code': instance.code,
      'region': instance.region,
      'land': instance.land,
    };

Code _$CodeFromJson(Map<String, dynamic> json) => Code(
      id: json['id'] as String,
      type: json['type'] as String,
      mappingId: json['mappingId'] as String,
    );

Map<String, dynamic> _$CodeToJson(Code instance) => <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'mappingId': instance.mappingId,
    };

Region _$RegionFromJson(Map<String, dynamic> json) => Region(
      area0: Area.fromJson(json['area0'] as Map<String, dynamic>),
      area1: Area.fromJson(json['area1'] as Map<String, dynamic>),
      area2: Area.fromJson(json['area2'] as Map<String, dynamic>),
      area3: Area.fromJson(json['area3'] as Map<String, dynamic>),
      area4: Area.fromJson(json['area4'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RegionToJson(Region instance) => <String, dynamic>{
      'area0': instance.area0,
      'area1': instance.area1,
      'area2': instance.area2,
      'area3': instance.area3,
      'area4': instance.area4,
    };

Area _$AreaFromJson(Map<String, dynamic> json) => Area(
      name: json['name'] as String,
      coords: Coords.fromJson(json['coords'] as Map<String, dynamic>),
      alias: json['alias'] as String?,
    );

Map<String, dynamic> _$AreaToJson(Area instance) => <String, dynamic>{
      'name': instance.name,
      'coords': instance.coords,
      'alias': instance.alias,
    };

Coords _$CoordsFromJson(Map<String, dynamic> json) => Coords(
      center: NaverCenter.fromJson(json['center'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CoordsToJson(Coords instance) => <String, dynamic>{
      'center': instance.center,
    };

NaverCenter _$NaverCenterFromJson(Map<String, dynamic> json) => NaverCenter(
      crs: json['crs'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$NaverCenterToJson(NaverCenter instance) =>
    <String, dynamic>{
      'crs': instance.crs,
      'x': instance.x,
      'y': instance.y,
    };

Land _$LandFromJson(Map<String, dynamic> json) => Land(
      type: json['type'] as String?,
      number1: json['number1'] as String?,
      number2: json['number2'] as String?,
      addition0: json['addition0'] == null
          ? null
          : Addition.fromJson(json['addition0'] as Map<String, dynamic>),
      addition1: json['addition1'] == null
          ? null
          : Addition.fromJson(json['addition1'] as Map<String, dynamic>),
      addition2: json['addition2'] == null
          ? null
          : Addition.fromJson(json['addition2'] as Map<String, dynamic>),
      addition3: json['addition3'] == null
          ? null
          : Addition.fromJson(json['addition3'] as Map<String, dynamic>),
      addition4: json['addition4'] == null
          ? null
          : Addition.fromJson(json['addition4'] as Map<String, dynamic>),
      name: json['name'] as String?,
      coords: json['coords'] == null
          ? null
          : Coords.fromJson(json['coords'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LandToJson(Land instance) => <String, dynamic>{
      'type': instance.type,
      'number1': instance.number1,
      'number2': instance.number2,
      'addition0': instance.addition0,
      'addition1': instance.addition1,
      'addition2': instance.addition2,
      'addition3': instance.addition3,
      'addition4': instance.addition4,
      'name': instance.name,
      'coords': instance.coords,
    };

Addition _$AdditionFromJson(Map<String, dynamic> json) => Addition(
      type: json['type'] as String,
      value: json['value'] as String,
    );

Map<String, dynamic> _$AdditionToJson(Addition instance) => <String, dynamic>{
      'type': instance.type,
      'value': instance.value,
    };
