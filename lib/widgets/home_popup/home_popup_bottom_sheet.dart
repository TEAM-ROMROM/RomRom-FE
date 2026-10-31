import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/home_popup_sheet_action.dart';
import 'package:romrom_fe/models/apis/objects/home_popup.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/device_type.dart';
import 'package:romrom_fe/utils/home_popup_link_opener.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';

/// 홈 공지·이벤트 팝업 바텀시트: 이미지 + 제목 + "자세히 알아보기" + "다시 보지 않기" / 닫기
/// 선택 결과만 반환 (저장·링크 이동은 HomePopupPresenter)
class HomePopupBottomSheet {
  const HomePopupBottomSheet._();

  // 태블릿 시트 최대 너비 (고정 px, 이미지가 화면 비례로 커지지 않게)
  static const double tabletSheetMaxWidth = 480;
  static const double sheetCornerRadius = 24;
  static const double primaryButtonHeight = 52;
  static const double horizontalPadding = 24;

  /// 바텀시트 노출 > 선택 결과 (바깥 탭·뒤로가기·드래그 닫기는 close)
  static Future<HomePopupSheetAction> show({required BuildContext context, required HomePopup popup}) async {
    final action = await showModalBottomSheet<HomePopupSheetAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: isTablet ? tabletSheetMaxWidth : double.infinity),
      builder: (_) => HomePopupSheetContent(popup: popup),
    );
    return action ?? HomePopupSheetAction.close;
  }
}

/// 바텀시트 본문 (테스트에서 직접 렌더링)
class HomePopupSheetContent extends StatelessWidget {
  const HomePopupSheetContent({super.key, required this.popup});

  final HomePopup popup;

  bool get _hasOpenableLink => isOpenableHomePopupLink(popup.linkUrl);

  void _closeWith(BuildContext context, HomePopupSheetAction action) => Navigator.of(context).pop(action);

  @override
  Widget build(BuildContext context) {
    final bottomSafeAreaPixels = MediaQuery.of(context).padding.bottom;
    final imageUrl = popup.imageUrl;
    final title = popup.title;
    final description = popup.description;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(HomePopupBottomSheet.sheetCornerRadius)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 팝업 이미지 (정사각형, 시트 너비 기준, 링크 있으면 탭 이동)
            if (imageUrl != null)
              GestureDetector(
                onTap: _hasOpenableLink ? () => _closeWith(context, HomePopupSheetAction.openLink) : null,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedImage(imageUrl: imageUrl, width: double.infinity),
                ),
              ),
            const SizedBox(height: 20),

            // 제목·설명
            if (title != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: HomePopupBottomSheet.horizontalPadding),
                child: Text(title, style: CustomTextStyles.h2.copyWith(fontWeight: FontWeight.w600, height: 1.3)),
              ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: HomePopupBottomSheet.horizontalPadding),
                child: Text(
                  description,
                  style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White, height: 1.4),
                ),
              ),
            ],

            // 자세히 알아보기 (이동 가능한 링크 있을 때만)
            if (_hasOpenableLink) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: HomePopupBottomSheet.horizontalPadding),
                child: _DetailButton(onTap: () => _closeWith(context, HomePopupSheetAction.openLink)),
              ),
            ],
            const SizedBox(height: 8),

            // 다시 보지 않기 / 닫기
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FooterTextButton(
                    label: '다시 보지 않기',
                    textColor: AppColors.opacity60White,
                    onTap: () => _closeWith(context, HomePopupSheetAction.dismissForever),
                  ),
                  _FooterTextButton(
                    label: '닫기',
                    textColor: AppColors.textColorWhite,
                    onTap: () => _closeWith(context, HomePopupSheetAction.close),
                  ),
                ],
              ),
            ),
            SizedBox(height: bottomSafeAreaPixels),
          ],
        ),
      ),
    );
  }
}

/// 노란 주요 버튼 "자세히 알아보기"
class _DetailButton extends StatelessWidget {
  const _DetailButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(10);
    return AppPressable(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Container(
        height: HomePopupBottomSheet.primaryButtonHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.primaryYellow, borderRadius: borderRadius),
        child: Text(
          '자세히 알아보기',
          style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600, color: AppColors.textColorBlack),
        ),
      ),
    );
  }
}

/// 하단 텍스트 버튼 (터치 영역 확보용 패딩 포함)
class _FooterTextButton extends StatelessWidget {
  const _FooterTextButton({required this.label, required this.textColor, required this.onTap});

  final String label;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      scaleDown: AppPressable.scaleIcon,
      enableRipple: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          label,
          style: CustomTextStyles.p2.copyWith(color: textColor, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
