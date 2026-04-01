import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:url_launcher/url_launcher.dart';

/// LOCATION 타입 메시지 말풍선
/// - Static Maps API 이미지 (220w × 130h)
/// - 주소 텍스트
/// - "지도에서 보기" 버튼 → 네이버지도 앱 or 웹 폴백
class ChatLocationBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatLocationBubble({super.key, required this.message});

  String? _buildStaticMapUrl() {
    final lat = message.latitude;
    final lng = message.longitude;
    if (lat == null || lng == null) return null;
    final center = '$lng,$lat';
    final markerPos = Uri.encodeComponent('$lng $lat');
    return '${AppUrls.naverStaticMapApiUrl}'
        '?w=264&h=160'
        '&center=$center'
        '&level=15'
        '&markers=type:d|size:mid|pos:$markerPos';
  }

  Future<void> _openNaverMap() async {
    final lat = message.latitude;
    final lng = message.longitude;
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
    final staticMapUrl = _buildStaticMapUrl();
    final address = message.address ?? '위치';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 220,
        decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 지도 이미지
            SizedBox(
              width: 220,
              height: 130,
              child: staticMapUrl != null
                  ? Image.network(
                      staticMapUrl,
                      width: 220,
                      height: 130,
                      fit: BoxFit.cover,
                      headers: {
                        'X-NCP-APIGW-API-KEY-ID': dotenv.get('NMF_CLIENT_ID'),
                        'X-NCP-APIGW-API-KEY': dotenv.get('NMF_CLIENT_SECRET'),
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.secondaryBlack2,
                        child: const Center(child: Icon(Icons.map_outlined, color: AppColors.opacity50White, size: 32)),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppColors.secondaryBlack2,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryYellow),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.secondaryBlack2,
                      child: const Center(child: Icon(Icons.map_outlined, color: AppColors.opacity50White, size: 32)),
                    ),
            ),
            // 주소 텍스트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                address,
                style: CustomTextStyles.p3.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w400),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 구분선
            Container(height: 1, color: AppColors.opacity10White),
            // 지도에서 보기 버튼
            GestureDetector(
              onTap: _openNaverMap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: Text(
                  '지도에서 보기',
                  style: CustomTextStyles.p3.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
