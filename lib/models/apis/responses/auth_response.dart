// lib/models/apis/responses/auth_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final String? accessToken;
  final String? refreshToken;
  final bool? isFirstLogin;
  final bool? isFirstItemPosted;
  final bool? isItemCategorySaved;
  final bool? isMemberLocationSaved;
  final bool? isMarketingInfoAgreed;
  final bool? isRequiredTermsAgreed;

  AuthResponse({
    this.accessToken,
    this.refreshToken,
    this.isFirstLogin,
    this.isFirstItemPosted,
    this.isItemCategorySaved,
    this.isMemberLocationSaved,
    this.isMarketingInfoAgreed,
    this.isRequiredTermsAgreed,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}