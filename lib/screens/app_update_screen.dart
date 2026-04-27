import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  bool _isLaunching = false;

  Future<void> _launchStore() async {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);
    try {
      final String storeUrl = Platform.isAndroid ? AppUrls.androidStoreUrl : AppUrls.iosStoreUrl;
      final Uri uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  Future<void> _onClosePressed() async {
    await _showExitConfirmDialog();
  }

  Future<void> _showExitConfirmDialog() async {
    await CommonModal.success(
      context: context,
      message: '안정적인 서비스를 위해서 롬롬 앱을\n최신버전으로 업데이트 해주세요.',
      buttonText: '확인',
      onConfirm: () {
        if (Platform.isAndroid) {
          SystemNavigator.pop();
        } else {
          exit(0);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _showExitConfirmDialog();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          systemNavigationBarColor: AppColors.primaryBlack,
        ),
        child: Scaffold(
          backgroundColor: AppColors.primaryBlack,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 앱바 (X버튼 왼쪽 고정, 타이틀 화면 중앙)
                Padding(
                  padding: EdgeInsets.only(top: 16.h, bottom: 16.h),
                  child: SizedBox(
                    height: 44.h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text('앱 업데이트', style: CustomTextStyles.h2),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 12.w),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _onClosePressed,
                              child: SizedBox(
                                width: 44.w,
                                height: 44.h,
                                child: Center(
                                  child: Icon(AppIcons.cancel, size: 24.sp, color: AppColors.textColorWhite),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 콘텐츠
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16.h),

                        // 헤드라인
                        RichText(
                          text: TextSpan(
                            style: CustomTextStyles.h1.copyWith(height: 1.2),
                            children: [
                              const TextSpan(text: '더 나은 교환을 위해\n롬롬이 '),
                              TextSpan(
                                text: '업데이트',
                                style: CustomTextStyles.h1.copyWith(color: AppColors.primaryYellow),
                              ),
                              const TextSpan(text: '되었어요!'),
                            ],
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // 서브텍스트
                        Text(
                          '안정적인 서비스 이용과 새로운 기능을 위해\n최신 버전으로 업데이트가 필요합니다.\n지금 바로 확인해보세요!',
                          style: CustomTextStyles.p1.copyWith(
                            color: AppColors.opacity60White,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 하단 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLaunching ? null : _launchStore,
                      child: Text('앱 업데이트 하러 가기', style: CustomTextStyles.p1.copyWith(color: AppColors.primaryBlack)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
