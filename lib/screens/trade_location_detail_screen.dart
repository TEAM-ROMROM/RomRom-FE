import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/current_location_button.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

/// 거래 희망 장소 상세 페이지
/// 물건 상세페이지에서 지도를 탭하면 이동하는 전체 화면 지도 뷰
class TradeLocationDetailScreen extends StatefulWidget {
  /// 거래 희망 위치 위도
  final double latitude;

  /// 거래 희망 위치 경도
  final double longitude;

  const TradeLocationDetailScreen({super.key, required this.latitude, required this.longitude});

  @override
  State<TradeLocationDetailScreen> createState() => _TradeLocationDetailScreenState();
}

class _TradeLocationDetailScreenState extends State<TradeLocationDetailScreen> {
  final _locationService = LocationService();
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: const CommonAppBar(title: '거래 희망 장소'),
      body: Stack(
        children: [
          // 전체 화면 네이버 지도
          Positioned.fill(
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(target: NLatLng(widget.latitude, widget.longitude), zoom: 15),
                logoAlign: NLogoAlign.leftBottom,
                logoMargin: NEdgeInsets.fromEdgeInsets(EdgeInsets.only(left: 24.w, bottom: 80.h)),
                indoorEnable: true,
                locationButtonEnable: false,
              ),
              onMapReady: (controller) async {
                if (!_mapControllerCompleter.isCompleted) {
                  _mapControllerCompleter.complete(controller);

                  // 현재 위치 추적 활성화 (파란색 점 표시)
                  controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);

                  // 거래 희망 위치 마커 추가
                  await controller.addOverlay(
                    NMarker(
                      id: 'trade_location',
                      position: NLatLng(widget.latitude, widget.longitude),
                      icon: const NOverlayImage.fromAssetImage("assets/images/location-pin-icon.png"),
                      size: NSize(33.w, 47.h),
                    ),
                  );
                }
              },
            ),
          ),
          // 현재 위치 버튼 (왼쪽 하단)
          Positioned(
            bottom: 24.h,
            left: 24.w,
            child: CurrentLocationButton(
              onTap: () async {
                final controller = await _mapControllerCompleter.future;

                // 현재 위치 가져오기
                final position = await _locationService.getCurrentPosition();
                if (position != null) {
                  final newPosition = _locationService.positionToLatLng(position);

                  // 지도를 현재 위치로 이동
                  await controller.updateCamera(
                    NCameraUpdate.fromCameraPosition(NCameraPosition(target: newPosition, zoom: 15)),
                  );
                } else {
                  // 위치 정보를 가져오지 못한 경우 토스트 메시지 표시
                  if (context.mounted) {
                    CommonSnackBar.show(context: context, message: '현재 위치를 가져올 수 없습니다.', type: SnackBarType.info);
                  }
                }
              },
              iconSize: 24.h,
            ),
          ),
          // 거래 위치 복귀 버튼 (오른쪽 하단)
          Positioned(
            bottom: 24.h,
            right: 24.w,
            child: _TradeLocationButton(
              onTap: () async {
                final controller = await _mapControllerCompleter.future;

                // 거래 희망 위치로 카메라 이동
                await controller.updateCamera(
                  NCameraUpdate.fromCameraPosition(
                    NCameraPosition(target: NLatLng(widget.latitude, widget.longitude), zoom: 15),
                  ),
                );
              },
              iconSize: 24.h,
            ),
          ),
        ],
      ),
    );
  }
}

/// 거래 위치로 이동 버튼 위젯
/// CurrentLocationButton과 동일한 스타일, 아이콘만 다름
class _TradeLocationButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double iconSize;

  const _TradeLocationButton({this.onTap, this.iconSize = 24.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.currentLocationButtonBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.currentLocationButtonBorder,
          width: 0.15.w,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.currentLocationButtonShadow.withValues(alpha: 0.25),
            blurRadius: 2.0,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: AppColors.currentLocationButtonShadow.withValues(alpha: 0.25),
            blurRadius: 2.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        iconSize: iconSize,
        icon: const Icon(AppIcons.location, color: AppColors.currentLocationButtonIcon),
      ),
    );
  }
}
