import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/location_verification/location_recheck_text_button.dart';
import 'package:shadex/shadex.dart';

/// GPS로 확인한 동네 표시: 고정 지도(제스처 전부 끔) + 중앙 핀 + 동네 이름 + 인증 버튼·다시 확인
/// 지도를 움직여 다른 위치를 고르는 기능 없음 (실제 현재 위치만 인증)
class LocationVerificationMapView extends StatelessWidget {
  // 동네가 보이는 지도 확대 수준
  static const double neighborhoodZoomLevel = 15;

  final NLatLng position;
  final String neighborhoodText;
  final bool isSaving;
  final VoidCallback onVerifyPressed;
  final VoidCallback onRecheckPressed;

  const LocationVerificationMapView({
    super.key,
    required this.position,
    required this.neighborhoodText,
    required this.isSaving,
    required this.onVerifyPressed,
    required this.onRecheckPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 확인 위치 고정 지도 (스크롤·확대·회전·기울기 끔)
        Positioned.fill(
          child: IgnorePointer(
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(target: position, zoom: neighborhoodZoomLevel),
                logoAlign: NLogoAlign.leftBottom,
                logoMargin: NEdgeInsets.fromEdgeInsets(const EdgeInsets.only(left: 24, bottom: 180)),
                scrollGesturesEnable: false,
                zoomGesturesEnable: false,
                rotationGesturesEnable: false,
                tiltGesturesEnable: false,
                stopGesturesEnable: false,
                locationButtonEnable: false,
              ),
            ),
          ),
        ),

        // 확인 위치 핀 (핀 끝이 화면 중앙)
        Center(
          child: Container(
            margin: EdgeInsets.only(bottom: 40.h),
            child: Shadex(
              shadowColor: AppColors.opacity20Black,
              shadowBlurRadius: 2.0,
              shadowOffset: const Offset(2, 2),
              child: SvgPicture.asset('assets/images/location-pin.svg'),
            ),
          ),
        ),

        // 동네 이름 + 인증 버튼 + 다시 확인
        Positioned(
          left: 24.w,
          right: 24.w,
          bottom: 24.h + MediaQuery.of(context).padding.bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.locationVerificationAreaLabel,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: Text(neighborhoodText, style: CustomTextStyles.p2),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '지금 있는 위치로만 동네를 인증할 수 있어요.',
                  style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White),
                  textAlign: TextAlign.center,
                ),
              ),
              CompletionButton(
                isEnabled: true,
                isLoading: isSaving,
                buttonText: '이 동네로 인증하기',
                enabledOnPressed: onVerifyPressed,
              ),
              LocationRecheckTextButton(isEnabled: !isSaving, onPressed: onRecheckPressed),
            ],
          ),
        ),
      ],
    );
  }
}
