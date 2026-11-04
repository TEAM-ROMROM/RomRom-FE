import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/services/native_ad_handle.dart';
import 'package:romrom_fe/widgets/home_tab/home_feed_native_ad_request.dart';
import 'package:romrom_fe/widgets/home_tab/home_feed_native_ad_preloader.dart';
import 'package:romrom_fe/widgets/skeletons/home_feed_skeleton.dart';

/// 홈 피드용 네이티브 광고 위젯
/// PageView 한 페이지를 물품 카드와 같은 크기로 채움 (레이아웃은 HomeFeedNativeAdStyle > 네이티브 팩토리)
/// 광고: [adPreloader]에서 칸별 광고를 빌려 그리고 종료 시 반납 (폐기는 보관소 책임 > 되돌아와도 재요청 없음)
/// 광고 ID 없음·로드 실패 > onLoadFailed (화면이 광고 칸을 접음, 스켈레톤이 남아 조작이 막히는 것 방지)
class NativeAdWidget extends StatefulWidget {
  final int adVirtualIndex;
  final HomeFeedNativeAdPreloader adPreloader;
  final VoidCallback? onLoadFailed;
  // 광고 요청 함수 (테스트 교체용, 기본: 홈 피드 광고 요청)
  final NativeAdHandle? Function(BuildContext context) requestAd;

  const NativeAdWidget({
    super.key,
    required this.adVirtualIndex,
    required this.adPreloader,
    this.onLoadFailed,
    this.requestAd = requestHomeFeedNativeAd,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAdHandle? _adHandle;
  // 광고 빌리기 1회 제한 (didChangeDependencies 반복 호출 대비)
  bool _hasBorrowedAd = false;

  // 글자 배율·안전영역을 읽어야 해서 initState 대신 첫 didChangeDependencies에서 빌림
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasBorrowedAd) return;
    _hasBorrowedAd = true;
    _borrowAd();
  }

  // 칸 접힘으로 같은 State가 다른 광고 칸을 맡으면 반납 후 다시 빌림
  @override
  void didUpdateWidget(covariant NativeAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adVirtualIndex == widget.adVirtualIndex && identical(oldWidget.adPreloader, widget.adPreloader)) {
      return;
    }
    _returnAd(oldWidget.adPreloader);
    _borrowAd();
  }

  /// 보관소에서 빌리기 (없으면 요청) > 로드 중이면 결과 대기 (광고 없음·실패 > 칸 접기 알림)
  void _borrowAd() {
    final adHandle = widget.adPreloader.borrowAd(widget.adVirtualIndex, () => widget.requestAd(context));
    _adHandle = adHandle;
    if (adHandle == null) {
      _notifyLoadFailedAfterFrame();
      return;
    }
    if (adHandle.isLoaded) return;
    adHandle.isLoadedFuture.then((isLoaded) {
      if (!mounted || !identical(_adHandle, adHandle)) return;
      if (isLoaded) {
        setState(() {});
        return;
      }
      _returnAd(widget.adPreloader);
      setState(() {});
      _notifyLoadFailedAfterFrame();
    });
  }

  void _returnAd(HomeFeedNativeAdPreloader adPreloader) {
    final adHandle = _adHandle;
    _adHandle = null;
    if (adHandle != null) adPreloader.returnAd(adHandle);
  }

  /// 로드 실패 알림 (빌드 중 부모 setState 방지 > 다음 프레임, 최신 콜백 사용)
  void _notifyLoadFailedAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLoadFailed?.call();
    });
  }

  @override
  void dispose() {
    _returnAd(widget.adPreloader);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adHandle = _adHandle;
    // 이미 받은 광고는 첫 빌드부터 바로 표시 (동기 isLoaded)
    if (adHandle == null || !adHandle.isLoaded) {
      // 광고 로드 전(또는 로드 실패) — 일반 피드 슬롯과 동일한 스켈레톤 노출
      return const HomeFeedSkeleton();
    }

    // 물품 카드(HomeFeedItemWidget)와 같은 페이지 전체 크기·바탕
    return SizedBox.expand(
      child: ColoredBox(
        color: AppColors.homeFeedCardBackground,
        child: AdWidget(ad: adHandle.nativeAd),
      ),
    );
  }
}
