// 물품 상세 교환 희망 장소: 주소 한 줄 + 고정 지도(마커), 지도 탭은 화면 콜백
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class ItemDetailTradeLocationSection extends StatelessWidget {
  // 지도 위젯 key 구분용 (detail_map_{itemId})
  final String itemId;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final VoidCallback onMapTapped;

  // 좌표 없을 때 지도 초기 위치 (서울시청)
  static const double _fallbackLatitude = 37.5666;
  static const double _fallbackLongitude = 126.9784;

  const ItemDetailTradeLocationSection({
    super.key,
    required this.itemId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.onMapTapped,
  });

  bool get _hasCoordinates => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 16.h, bottom: 120.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('교환희망장소', style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w600, height: 1.4)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(AppIcons.location, size: 13.sp, color: AppColors.opacity80White),
              SizedBox(width: 4.w),
              Text(locationName, style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 200.h,
            child: ClipRRect(borderRadius: BorderRadius.circular(4.r), child: _buildMap()),
          ),
        ],
      ),
    );
  }

  /// 스크롤·줌 잠긴 지도 (좌표 있으면 위치 핀 마커)
  Widget _buildMap() {
    return NaverMap(
      key: ValueKey('detail_map_$itemId'),
      forceGesture: true,
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: NLatLng(latitude ?? _fallbackLatitude, longitude ?? _fallbackLongitude),
          zoom: 15,
        ),
        scrollGesturesEnable: false,
        zoomGesturesEnable: false,
      ),
      onMapReady: (controller) {
        if (_hasCoordinates) {
          controller.addOverlay(
            NMarker(
              id: 'item_location',
              position: NLatLng(latitude!, longitude!),
              icon: const NOverlayImage.fromAssetImage("assets/images/location-pin-icon.png"),
              size: NSize(33.w, 47.h),
            ),
          );
        }
      },
      // 지도 탭 시 거래 희망 장소 상세 페이지로 이동 (좌표 있을 때만)
      onMapTapped: (point, latLng) {
        if (_hasCoordinates) onMapTapped();
      },
    );
  }
}
