import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/home_tab/home_feed_native_ad_handle.dart';
import 'package:romrom_fe/widgets/home_tab/home_feed_native_ad_preloader.dart';
import 'package:romrom_fe/widgets/skeletons/home_feed_skeleton.dart';

/// 홈 피드용 네이티브 광고 위젯
/// PageView 한 페이지를 물품 카드와 같은 크기로 채움 (레이아웃은 HomeFeedNativeAdStyle > 네이티브 팩토리)
/// 광고: 미리 받은 광고 우선 ([adPreloader]) > 없으면 직접 요청
/// 광고 ID 없음·로드 실패 > onLoadFailed (화면이 광고 칸을 접음, 스켈레톤이 남아 조작이 막히는 것 방지)
class NativeAdWidget extends StatefulWidget {
  final VoidCallback? onLoadFailed;
  final HomeFeedNativeAdPreloader? adPreloader;

  const NativeAdWidget({super.key, this.onLoadFailed, this.adPreloader});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  HomeFeedNativeAdHandle? _adHandle;
  bool _isLoaded = false;
  // 광고 요청 1회 제한 (didChangeDependencies 반복 호출 대비)
  bool _hasRequestedAd = false;

  // 글자 배율·안전영역을 읽어야 해서 initState 대신 첫 didChangeDependencies에서 요청
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasRequestedAd) return;
    _hasRequestedAd = true;
    _loadAd();
  }

  /// 미리 받은 광고 가져오기 > 없으면 직접 요청 > 로드 결과 대기 (광고 ID 없음·실패 > 칸 접기 알림)
  void _loadAd() {
    final adHandle = widget.adPreloader?.takePreloadedAd() ?? requestHomeFeedNativeAd(context);
    if (adHandle == null) {
      _notifyLoadFailedAfterFrame();
      return;
    }
    _adHandle = adHandle;
    adHandle.isLoadedFuture.then((isLoaded) {
      if (!mounted || !identical(_adHandle, adHandle)) return;
      if (isLoaded) {
        setState(() => _isLoaded = true);
        return;
      }
      setState(() => _adHandle = null);
      _notifyLoadFailedAfterFrame();
    });
  }

  /// 로드 실패 알림 (빌드 중 부모 setState 방지 > 다음 프레임, 최신 콜백 사용)
  void _notifyLoadFailedAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLoadFailed?.call();
    });
  }

  @override
  void dispose() {
    _adHandle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adHandle = _adHandle;
    if (!_isLoaded || adHandle == null) {
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
