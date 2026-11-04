import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/services/ad_mob_service.dart';
import 'package:romrom_fe/services/native_ad_handle.dart';
import 'package:romrom_fe/widgets/list_native_ad/list_native_ad_style.dart';

// 네이티브 팩토리 ID (등록 이름과 같은 값: ios/Runner/AppDelegate.swift, android MainActivity.kt)
const String listNativeAdFactoryId = 'listNativeAd';

/// 목록 광고 1개 요청: 광고 ID 없음 > null (AdChoices는 SDK가 오른쪽 위에 자동 배치, CTA와 떨어짐)
NativeAdHandle? requestListNativeAd(BuildContext context) {
  return requestNativeAd(
    adUnitId: AdMobService.nativeListAdUnitId,
    factoryId: listNativeAdFactoryId,
    customOptions: ListNativeAdStyle.buildCustomOptions(textScaler: MediaQuery.textScalerOf(context)),
    nativeAdOptions: NativeAdOptions(adChoicesPlacement: AdChoicesPlacement.topRightCorner),
    logLabel: 'list',
  );
}

/// 목록 사이 네이티브 광고 칸: 로드 중 같은 높이 자리 확보(행 밀림 방지) > 표시, 광고 없음·실패 > 높이 0으로 접힘
/// 스크롤로 벗어나도 유지 (keepAlive > 되돌아와도 재요청 없음), 칸 종료 시 광고 폐기
class ListNativeAdCell extends StatefulWidget {
  const ListNativeAdCell({
    super.key,
    this.horizontalPadding = 0,
    this.bottomSeparator,
    this.requestAd = requestListNativeAd,
  });

  // 목록 행과 같은 좌우 여백
  final double horizontalPadding;
  // 칸 아래 구분선 (칸과 함께 접힘 > 실패 시 구분선 중복 없음)
  final Widget? bottomSeparator;
  // 광고 요청 함수 (테스트 교체용)
  final NativeAdHandle? Function(BuildContext context) requestAd;

  @override
  State<ListNativeAdCell> createState() => _ListNativeAdCellState();
}

class _ListNativeAdCellState extends State<ListNativeAdCell> with AutomaticKeepAliveClientMixin {
  NativeAdHandle? _adHandle;
  bool _hasRequestedAd = false;
  bool _hasLoadFailed = false;

  @override
  bool get wantKeepAlive => !_hasLoadFailed;

  // 글자 배율을 읽어야 해서 initState 대신 첫 didChangeDependencies에서 요청
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasRequestedAd) return;
    _hasRequestedAd = true;
    final adHandle = widget.requestAd(context);
    if (adHandle == null) {
      _hasLoadFailed = true;
      return;
    }
    _adHandle = adHandle;
    if (adHandle.isLoaded) return;
    adHandle.isLoadedFuture.then((isLoaded) {
      if (!mounted || !identical(_adHandle, adHandle)) return;
      setState(() {
        if (isLoaded) return;
        _hasLoadFailed = true;
        _adHandle = null;
      });
      updateKeepAlive();
    });
  }

  @override
  void dispose() {
    _adHandle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: _hasLoadFailed ? const SizedBox(width: double.infinity) : _buildAdContent(context),
    );
  }

  Widget _buildAdContent(BuildContext context) {
    final adHandle = _adHandle;
    final isAdLoaded = adHandle != null && adHandle.isLoaded;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.horizontalPadding,
            vertical: ListNativeAdStyle.outerVerticalMargin,
          ),
          child: SizedBox(
            height: ListNativeAdStyle.cellHeight(MediaQuery.textScalerOf(context)),
            width: double.infinity,
            // 로드 전: 광고 칸과 같은 바탕 자리만 (광고 표시 없이 높이 확보)
            child: isAdLoaded
                ? AdWidget(ad: adHandle.nativeAd)
                : const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.listNativeAdBackground,
                      borderRadius: BorderRadius.all(Radius.circular(ListNativeAdStyle.cornerRadius)),
                    ),
                  ),
          ),
        ),
        ?widget.bottomSeparator,
      ],
    );
  }
}
