import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_trade_option.dart' as trade_opt;
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/apis/social_logout_service.dart';
import 'package:romrom_fe/services/auth_service.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/item_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPageTabScreen extends StatefulWidget {
  const MyPageTabScreen({super.key});

  @override
  State<MyPageTabScreen> createState() => _MyPageTabScreenState();
}

class _MyPageTabScreenState extends State<MyPageTabScreen> {
  final List<Item> _myItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyItems();
  }

  /// 내 물품 리스트 로드
  Future<void> _loadMyItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final itemApi = ItemApi();
      final request = ItemRequest(pageNumber: 0, pageSize: 30);
      final response = await itemApi.getMyItems(request);

      setState(() {
        _myItems
          ..clear()
          ..addAll(response.itemPage?.content ?? []);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('내 물품 목록 로드 실패: $e')));
      }
    }
  }

  /// 서버에서 받은 카테고리(serverName) → 한글 이름 매핑
  String _mapItemCategory(String? categoryServerName) {
    if (categoryServerName == null) return '-';
    for (final category in ItemCategories.values) {
      if (category.serverName == categoryServerName) {
        return category.name;
      }
    }
    return categoryServerName; // 매칭 실패 시 그대로 반환
  }

  /// 서버에서 받은 거래 옵션(serverName) 리스트 → ItemTradeOption enum 리스트 매핑
  List<trade_opt.ItemTradeOption> _mapTradeOptions(List<String>? options) {
    if (options == null) return [];
    final result = <trade_opt.ItemTradeOption>[];
    for (final opt in options) {
      try {
        final match = trade_opt.ItemTradeOption.values
            .firstWhere((e) => e.serverName == opt);
        result.add(match);
      } catch (_) {
        // 매칭 실패 시 건너뛰기
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 물품 카드 리스트 영역
          SizedBox(
            height: 500.h,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _myItems.isEmpty
                    ? Center(
                        child:
                            Text('등록한 물품이 없습니다.', style: CustomTextStyles.h3),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemBuilder: (context, index) {
                          final item = _myItems[index];
                          return SizedBox(
                            width: 85.w,
                            child: ItemCard(
                              itemId: item.itemId ?? 'unknown',
                              itemCategoryLabel:
                                  _mapItemCategory(item.itemCategory),
                              itemName: item.itemName ?? '',
                              itemCardImageUrl: item.primaryImageUrl != null
                                  ? item.primaryImageUrl!
                                  : 'https://picsum.photos/400/300',
                              itemOptions:
                                  _mapTradeOptions(item.itemTradeOptions),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => SizedBox(width: 12.w),
                        itemCount: _myItems.length,
                      ),
          ),
          _buildActionButton(
            onPressed: () => AuthService().logout(context),
            backgroundColor: Colors.pink[300],
            text: '로그아웃',
          ),
          SizedBox(height: 20.h),
          _buildActionButton(
            onPressed: () => _handleDeleteMemberButtonTap(context),
            backgroundColor: Colors.red[400],
            text: '회원탈퇴',
          ),
        ],
      ),
    );
  }

  /// 액션 버튼 위젯 생성
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required Color? backgroundColor,
    required String text,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(backgroundColor),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        ),
      ),
      child: Text(text,
          style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite)),
    );
  }

  /// 회원 탈퇴 처리
  void _handleDeleteMemberButtonTap(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.primaryBlack,
        title: Text('회원 탈퇴', style: CustomTextStyles.h3),
        content: Text(
          '정말 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
          style: CustomTextStyles.p2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('취소', style: CustomTextStyles.p2),
          ),
          TextButton(
            onPressed: () => _confirmDeleteMember(dialogContext, context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('탈퇴하기', style: CustomTextStyles.p2),
          ),
        ],
      ),
    );
  }

  /// 회원 탈퇴 확인 후 처리
  Future<void> _confirmDeleteMember(
      BuildContext dialogContext, BuildContext context) async {
    Navigator.pop(dialogContext); // 다이얼로그 닫기

    // 회원 탈퇴 진행
    final memberApi = MemberApi();
    final isSuccess = await memberApi.deleteMember();

    // context가 여전히 유효한지 확인
    if (!context.mounted) return;

    if (isSuccess) {
      // 토큰 삭제 후 로그인 화면으로 이동
      final tokenManager = TokenManager();
      await tokenManager.deleteTokens();

      // 소셜 플랫폼별 로그아웃 처리
      final socialLogoutService = SocialLogoutService();
      await socialLogoutService.performSocialLogout();

      // 메인 화면 블러 처리 변수 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isFirstMainScreen');

      // context가 여전히 유효한지 다시 확인
      if (!context.mounted) return;

      // 로그인 페이지로 이동
      context.navigateTo(
          screen: const LoginScreen(),
          type: NavigationTypes.pushAndRemoveUntil);
    } else {
      // 실패 안내
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원 탈퇴에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }
}
