import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/responses/naver_address_response.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/auth_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/category_completion_button.dart';
import 'package:romrom_fe/widgets/onboarding_progress_header.dart';
import 'package:romrom_fe/widgets/onboarding_title_header.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  final int _totalSteps = 3;

  // 현재 단계에 따른 타이틀 정보
  Map<int, Map<String, String>> stepTitles = {
    1: {'title': '기본 정보 입력', 'subtitle': '서비스 이용을 위한 정보를 입력해주세요'},
    2: {'title': '동네 인증하기', 'subtitle': '내 위치를 인증해주세요'},
    3: {'title': '카테고리 선택', 'subtitle': '관심있는 분야를 선택해주세요!'},
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 다음 페이지로 이동
  void _goToNextPage() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep += 1;
      });
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 이전 페이지로 이동
  void _goToPrevPage() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep -= 1;
      });
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 첫 페이지에서 뒤로가기 시 로그아웃 처리 후 로그인 화면으로 이동
      final AuthService authService = AuthService();
      authService.logout(context);
    }
  }

  // 온보딩 완료 후 메인 화면으로 이동
  void _completeOnboarding() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTitles = stepTitles[_currentStep]!;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태표시줄 여백
          SizedBox(height: MediaQuery.of(context).padding.top),

          // 프로그레스 헤더 - PageView 외부에 배치하여 고정
          OnboardingProgressHeader(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            onBackPressed: _goToPrevPage,
          ),

          // 타이틀 헤더 - PageView 외부에 배치하여 고정
          OnboardingTitleHeader(
            title: currentTitles['title']!,
            subtitle: currentTitles['subtitle']!,
          ),

          // PageView로 내용만 전환
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // 사용자 스와이프 비활성화
              children: [
                _UserInfoContent(onNext: _goToNextPage),
                _LocationVerificationContent(onNext: _goToNextPage),
                _CategorySelectionContent(onComplete: _completeOnboarding),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// 1단계: 사용자 정보 입력 내용
class _UserInfoContent extends StatefulWidget {
  final VoidCallback onNext;

  const _UserInfoContent({required this.onNext});

  @override
  State<_UserInfoContent> createState() => _UserInfoContentState();
}

class _UserInfoContentState extends State<_UserInfoContent> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final FocusNode _nicknameFocus = FocusNode();
  final FocusNode _birthdayFocus = FocusNode();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_checkButtonState);
    _birthdayController.addListener(_checkButtonState);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthdayController.dispose();
    _nicknameFocus.dispose();
    _birthdayFocus.dispose();
    super.dispose();
  }

  void _checkButtonState() {
    final bool isEnabled = _nicknameController.text.isNotEmpty &&
        _birthdayController.text.isNotEmpty;
    if (isEnabled != _isButtonEnabled) {
      setState(() => _isButtonEnabled = isEnabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32.h),

          // 닉네임 입력 필드
          TextField(
            controller: _nicknameController,
            focusNode: _nicknameFocus,
            decoration: InputDecoration(
              labelText: '닉네임',
              hintText: '2~8자 이내로 입력해주세요',
              labelStyle: CustomTextStyles.p2,
              hintStyle: CustomTextStyles.p3.copyWith(
                color: AppColors.opacity50White,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.opacity50White, width: 1.w),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.primaryYellow, width: 1.w),
              ),
            ),
            style: CustomTextStyles.p2,
          ),

          SizedBox(height: 32.h),

          // 생년월일 입력 필드
          TextField(
            controller: _birthdayController,
            focusNode: _birthdayFocus,
            decoration: InputDecoration(
              labelText: '생년월일',
              hintText: 'YYYY-MM-DD 형식으로 입력해주세요',
              labelStyle: CustomTextStyles.p2,
              hintStyle: CustomTextStyles.p3.copyWith(
                color: AppColors.opacity50White,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.opacity50White, width: 1.w),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.primaryYellow, width: 1.w),
              ),
            ),
            style: CustomTextStyles.p2,
          ),

          // 하단 여백 채우기
          const Spacer(),

          // 다음 단계 버튼
          Padding(
            padding: EdgeInsets.only(bottom: 48.h),
            child: ElevatedButton(
              onPressed: _isButtonEnabled
                  ? () async {
                      // 여기에 사용자 정보 저장 로직 추가
                      widget.onNext();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isButtonEnabled
                    ? AppColors.primaryYellow
                    : AppColors.primaryYellow.withOpacity(0.3),
                minimumSize: Size(double.infinity, 56.h),
              ),
              child: Text(
                '다음',
                style: CustomTextStyles.p1.copyWith(
                  color: _isButtonEnabled ? Colors.black : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2단계: 위치 인증 내용
class _LocationVerificationContent extends StatefulWidget {
  final VoidCallback onNext;

  const _LocationVerificationContent({required this.onNext});

  @override
  State<_LocationVerificationContent> createState() =>
      _LocationVerificationContentState();
}

class _LocationVerificationContentState
    extends State<_LocationVerificationContent> {
  // 위치 인증 화면의 상태 변수들
  NLatLng? _currentPosition;
  String currentAdress = '';
  String siDo = '';
  String siGunGu = '';
  String eupMyoenDong = '';
  String? ri;
  final Completer<NaverMapController> mapControllerCompleter = Completer();

  @override
  void initState() {
    super.initState();
    _permission();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 맵 영역
        Expanded(
          flex: 341,
          child: Stack(
            children: [
              NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: _currentPosition!,
                    zoom: 15,
                  ),
                  logoAlign: NLogoAlign.leftBottom,
                  logoMargin: NEdgeInsets.fromEdgeInsets(
                    EdgeInsets.only(left: 24.w, bottom: 20.h),
                  ),
                  indoorEnable: true,
                  locationButtonEnable: false,
                  consumeSymbolTapEvents: false,
                ),
                forceGesture: false,
                onMapReady: (controller) async {
                  if (!mapControllerCompleter.isCompleted) {
                    mapControllerCompleter.complete(controller);
                  }
                  await getAddressByNaverApi(_currentPosition!);
                  await controller
                      .setLocationTrackingMode(NLocationTrackingMode.follow);
                },
              ),
              // 현재 위치 버튼
              Positioned(
                bottom: 48.h,
                left: 24.w,
                child: GestureDetector(
                  onTap: () async {
                    final controller = await mapControllerCompleter.future;
                    await controller
                        .setLocationTrackingMode(NLocationTrackingMode.follow);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.currentLocationButtonBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.currentLocationButtonBorder,
                          width: 0.15.w,
                          strokeAlign: BorderSide.strokeAlignInside),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.currentLocationButtonShadow
                              .withValues(alpha: 0.25),
                          blurRadius: 2.0,
                          offset: const Offset(0, 0),
                        ),
                        BoxShadow(
                          color: AppColors.currentLocationButtonShadow
                              .withValues(alpha: 0.25),
                          blurRadius: 2.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () async {
                        final controller = await mapControllerCompleter.future;
                        await controller.setLocationTrackingMode(
                            NLocationTrackingMode.follow);
                      },
                      iconSize: 24.h,
                      icon: const Icon(
                        AppIcons.currentLocation,
                        color: AppColors.currentLocationButtonIcon,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),

        // 위치 정보 및 버튼 영역
        Expanded(
          flex: 370,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 32.0.h),
                Text(
                  '현재 위치가 $currentAdress 이내에 있어요',
                  style: CustomTextStyles.p2,
                ),
                SizedBox(height: 20.0.h),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20.0.w, vertical: 12.0.h),
                  decoration: BoxDecoration(
                    color: AppColors.locationVerificationAreaLabel,
                    borderRadius: BorderRadius.circular(100.0.r),
                  ),
                  child: Text(
                    "$siDo $siGunGu $eupMyoenDong",
                    style: CustomTextStyles.p2,
                  ),
                ),
                SizedBox(height: 113.0.h),
                SizedBox(
                  width: 316.w,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: AppColors.textColorBlack,
                      padding: EdgeInsets.symmetric(vertical: 20.0.h),
                      minimumSize: Size(316.w, 0),
                    ),
                    onPressed: () => _onVerifyLocationPressed(),
                    child: Text(
                      '위치 인증하기',
                      style: CustomTextStyles.p1.copyWith(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 위치 인증 버튼 클릭 시 처리
  Future<void> _onVerifyLocationPressed() async {
    if (_currentPosition != null) {
      try {
        // 위치 정보가 비어있는지 확인
        if (siDo.isEmpty || siGunGu.isEmpty || eupMyoenDong.isEmpty) {
          await getAddressByNaverApi(_currentPosition!);

          if (siDo.isEmpty || siGunGu.isEmpty || eupMyoenDong.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('위치 정보를 가져오지 못했습니다. 다시 시도해주세요.')),
              );
            }
            return;
          }
        }

        await MemberApi().saveMemberLocation(
          longitude: _currentPosition!.longitude,
          latitude: _currentPosition!.latitude,
          siDo: siDo,
          siGunGu: siGunGu,
          eupMyoenDong: eupMyoenDong,
          ri: ri,
        );

        // 다음 단계로 이동
        widget.onNext();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('위치 저장에 실패했습니다: $e')),
          );
        }
      }
    }
  }

  // 위치 권한 요청 (기존 코드)
  Future<void> _permission() async {
    var requestStatus = await Permission.location.request();
    var status = await Permission.location.status;

    if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      await _getCurrentPosition();
    }
  }

  // 현재 위치 가져오기 (기존 코드)
  Future<void> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = NLatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      log('Error getting location: $e');
    }
  }

  // 네이버 API를 사용한 주소 정보 가져오기 (기존 코드)
  Future<void> getAddressByNaverApi(NLatLng position) async {
    // 기존 LocationVerificationScreen의 메서드 구현 그대로 사용
    const String naverReverseGeoCodeApiUrl = AppUrls.naverReverseGeoCodeApiUrl;
    String coords = "${position.longitude},${position.latitude}";
    const String orders = "legalcode";
    const String output = "json";

    try {
      final requestUrl =
          "$naverReverseGeoCodeApiUrl?coords=$coords&orders=$orders&output=$output";

      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {
          "X-NCP-APIGW-API-KEY-ID": dotenv.get('NMF_CLIENT_ID'),
          "X-NCP-APIGW-API-KEY": dotenv.get('NMF_CLIENT_SECRET'),
        },
      );

      if (response.statusCode == 200) {
        final NaverAddressResponse addressData =
            NaverAddressResponse.fromJson(json.decode(response.body));

        if (addressData.results.isNotEmpty) {
          final region = addressData.results[0].region;

          setState(() {
            siDo = region.area1.name;
            siGunGu = region.area2.name;
            eupMyoenDong = region.area3.name;
            ri = region.area4.name.isNotEmpty ? region.area4.name : null;
            currentAdress = eupMyoenDong;
          });
        }
      }
    } catch (e) {
      log("주소 요청 중 오류 발생: $e");
    }
  }
}

/// 3단계: 카테고리 선택 내용
class _CategorySelectionContent extends StatefulWidget {
  final VoidCallback onComplete;

  const _CategorySelectionContent({required this.onComplete});

  @override
  State<_CategorySelectionContent> createState() =>
      _CategorySelectionContentState();
}

class _CategorySelectionContentState extends State<_CategorySelectionContent> {
  final List<int> selectedCategories = [];
  final memberApi = MemberApi();

  bool get isSelectedCategories => selectedCategories.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32.h),
          // 카테고리 칩 표시
          Expanded(
            child: SingleChildScrollView(
              child: _buildCategoryChips(context),
            ),
          ),

          // 완료 버튼 - CategoryCompletionButton 위젯으로 변경
          Padding(
            padding: EdgeInsets.only(bottom: 48.h),
            child: Center(
              child: CategoryCompletionButton(
                isEnabled: isSelectedCategories,
                enabledOnPressed: () async {
                  try {
                    await memberApi.savePreferredCategories(selectedCategories);
                    widget.onComplete();
                  } catch (e) {
                    debugPrint("Error: $e");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('카테고리 저장에 실패했습니다: $e')),
                      );
                    }
                  }
                },
                buttonText: '완료',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 기존 카테고리 관련 메서드는 유지합니다
  Widget _buildCategoryChips(BuildContext context) {
    return Wrap(
      spacing: 8.0.w,
      runSpacing: 12.0.h,
      children: ItemCategories.values
          .map((category) => _buildCategoryChip(context, category))
          .toList(),
    );
  }

  Widget _buildCategoryChip(BuildContext context, ItemCategories category) {
    final bool isSelected = selectedCategories.contains(category.id);

    return RawChip(
      label: Text(
        category.name,
        style: CustomTextStyles.p2.copyWith(
          fontSize: adjustedFontSize(context, 14.0),
          color:
          isSelected ? AppColors.textColorBlack : AppColors.textColorWhite,
          wordSpacing: -0.32.w,
        ),
      ),
      labelPadding: EdgeInsets.zero,
      padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 10.0.h),
      selected: isSelected,
      selectedColor: AppColors.primaryYellow,
      backgroundColor: AppColors.primaryBlack,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color:
          isSelected ? AppColors.primaryYellow : AppColors.textColorWhite,
          strokeAlign: BorderSide.strokeAlignInside,
          width: 1.0.w,
        ),
        borderRadius: BorderRadiusDirectional.circular(100.r),
      ),
      checkmarkColor: Colors.transparent,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (bool selected) =>
          _toggleCategorySelection(category.id, selected),
    );
  }

  void _toggleCategorySelection(int categoryId, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedCategories.add(categoryId);
      } else {
        selectedCategories.remove(categoryId);
      }
      debugPrint("선택 카테고리 : $selectedCategories");
    });
  }
}