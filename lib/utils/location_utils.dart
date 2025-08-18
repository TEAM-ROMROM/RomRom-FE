import 'package:romrom_fe/models/location_address.dart';

class LocationUtils {
  /// LocationAddress를 포맷팅된 문자열로 변환
  /// 시/도 + 시/군/구 + 읍/면/동 + 리 형식으로 반환
  static String formatAddress(LocationAddress address) {
    final parts = <String>[];
    
    // 시/도
    if (address.siDo.isNotEmpty) {
      parts.add(address.siDo);
    }
    
    // 시/군/구
    if (address.siGunGu.isNotEmpty) {
      parts.add(address.siGunGu);
    }
    
    // 읍/면/동
    if (address.eupMyoenDong.isNotEmpty) {
      parts.add(address.eupMyoenDong);
    }
    
    // 리
    if (address.ri != null && address.ri!.isNotEmpty) {
      parts.add(address.ri!);
    }
    
    return parts.join(' ').trim();
  }
  
  /// 짧은 주소 형식 (읍/면/동만 표시)
  static String formatShortAddress(LocationAddress address) {
    return address.eupMyoenDong.trim();
  }
  
  /// 중간 길이 주소 형식 (시/군/구 + 읍/면/동)
  static String formatMediumAddress(LocationAddress address) {
    final parts = <String>[];
    
    if (address.siGunGu.isNotEmpty) {
      parts.add(address.siGunGu);
    }
    
    if (address.eupMyoenDong.isNotEmpty) {
      parts.add(address.eupMyoenDong);
    }
    
    return parts.join(' ').trim();
  }
  
  /// 문자열에서 LocationAddress 생성 (간단한 파싱)
  /// "서울특별시 강남구 역삼동" 형식의 문자열을 파싱
  static LocationAddress? parseFromString(String addressString) {
    if (addressString.isEmpty) return null;
    
    final parts = addressString.split(' ');
    if (parts.isEmpty) return null;
    
    // 최소한 동 정보는 있어야 함
    final eupMyoenDong = parts.isNotEmpty ? parts.last : '';
    if (eupMyoenDong.isEmpty) return null;
    
    return LocationAddress(
      siDo: parts.length > 2 ? parts[0] : '',
      siGunGu: parts.length > 1 ? parts[parts.length - 2] : '',
      eupMyoenDong: eupMyoenDong,
      ri: null,
    );
  }
}