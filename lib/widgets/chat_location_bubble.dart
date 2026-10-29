import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/utils/location_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// LOCATION 타입 메시지 말풍선
/// - Static Maps API 이미지 (264w × 176h) — CachedImage로 디스크 캐시 + 인증 헤더
/// - 주소 텍스트 (lat/lng → 역지오코딩)
/// - "지도에서 보기" 버튼 → 네이버지도 앱 or 웹 폴백
class ChatLocationBubble extends StatefulWidget {
  final ChatMessage message;

  const ChatLocationBubble({super.key, required this.message});

  @override
  State<ChatLocationBubble> createState() => _ChatLocationBubbleState();
}

class _ChatLocationBubbleState extends State<ChatLocationBubble> {
  String _address = '';

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    final lat = widget.message.latitude;
    final lng = widget.message.longitude;
    if (lat == null || lng == null) return;

    final LocationAddress? result = await LocationService().getAddressFromCoordinates(NLatLng(lat, lng));
    if (!mounted) return;

    if (result != null) {
      setState(() => _address = LocationUtils.formatAddress(result));
    }
  }

  Future<void> _openNaverMap() async {
    final lat = widget.message.latitude;
    final lng = widget.message.longitude;
    if (lat == null || lng == null) return;

    final appUri = Uri.parse('nmap://map?lat=$lat&lng=$lng&zoom=15&appname=com.alom.romrom');
    final webUri = Uri.parse('https://map.naver.com/v5/?c=$lng,$lat,15,0,0,0,dh');

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bubbleWidth = 264.w;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: bubbleWidth,
        decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 지도 이미지
            SizedBox(width: bubbleWidth, height: 176.h, child: _buildMapImage(bubbleWidth)),
            // 주소 텍스트
            Padding(
              padding: EdgeInsets.only(left: 12.w, top: 9.h, bottom: 1.h),
              child: Text(
                _address.isNotEmpty ? _address : '위치',
                style: CustomTextStyles.p3.copyWith(height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 지도에서 보기 버튼
            Padding(
              padding: EdgeInsets.all(8.0.w),
              child: GestureDetector(
                onTap: _openNaverMap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: BoxDecoration(color: AppColors.secondaryBlack2, borderRadius: BorderRadius.circular(4.r)),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  alignment: Alignment.center,
                  child: Text(
                    '지도에서 보기',
                    style: CustomTextStyles.p3.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 정적 지도 URL: 좌표 > 중심·마커 쿼리 (좌표 없으면 null)
  String? _buildStaticMapUrl() {
    final lat = widget.message.latitude;
    final lng = widget.message.longitude;
    if (lat == null || lng == null) return null;

    return Uri.parse(AppUrls.naverStaticMapApiUrl)
        .replace(
          queryParameters: {
            'w': '528',
            'h': '352',
            'center': '$lng,$lat',
            'level': '15',
            'markers': 'type:d|size:mid|color:0xFFC300|pos:$lng $lat',
          },
        )
        .toString();
  }

  Widget _buildMapImage(double width) {
    final mapUrl = _buildStaticMapUrl();
    final mapErrorWidget = Container(
      color: AppColors.secondaryBlack2,
      child: const Center(child: Icon(Icons.map_outlined, color: AppColors.opacity50White, size: 32)),
    );
    // NCP API 키 누락 시 지도 에러 위젯 (dotenv.get 예외 방지)
    final ncpClientId = dotenv.maybeGet('NMF_CLIENT_ID');
    final ncpClientSecret = dotenv.maybeGet('NMF_CLIENT_SECRET');
    if (mapUrl == null || ncpClientId == null || ncpClientSecret == null) return mapErrorWidget;

    return CachedImage(
      imageUrl: mapUrl,
      width: width,
      height: 176.h,
      fit: BoxFit.cover,
      // NCP API 키 헤더 (상수라 캐시 키에 포함하지 않음)
      httpHeaders: {'x-ncp-apigw-api-key-id': ncpClientId, 'x-ncp-apigw-api-key': ncpClientSecret},
      placeholder: Container(
        color: AppColors.secondaryBlack2,
        // 지도 이미지 로딩 중 스피너
        child: const Center(child: CommonLoadingIndicator()),
      ),
      errorWidget: mapErrorWidget,
    );
  }
}
