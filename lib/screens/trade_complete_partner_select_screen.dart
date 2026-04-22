import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/apis/chat_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/item_label_utils.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/trade_request_target_preview.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

/// 교환 완료 처리 시 교환 상대를 선택하는 화면
class TradeCompletePartnerSelectScreen extends StatefulWidget {
  final Item item;

  const TradeCompletePartnerSelectScreen({super.key, required this.item});

  @override
  State<TradeCompletePartnerSelectScreen> createState() => _TradeCompletePartnerSelectScreenState();
}

class _TradeCompletePartnerSelectScreenState extends State<TradeCompletePartnerSelectScreen> {
  bool _isLoading = true;
  List<ChatRoomDetailDto> _chatRooms = [];
  String? _selectedChatRoomId;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  /// 물품 ID로 채팅방 목록 불러오기
  Future<void> _loadChatRooms() async {
    final itemId = widget.item.itemId;
    if (itemId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await ChatApi().getChatRoomsByItemId(itemId: itemId);
      if (mounted) {
        setState(() {
          _chatRooms = result.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CommonSnackBar.show(context: context, message: '채팅 목록을 불러오지 못했습니다.', type: SnackBarType.error);
      }
    }
  }

  /// 채팅방으로 이동하여 교환 완료 요청 전송
  void _onConfirm() {
    if (_selectedChatRoomId == null) return;
    Navigator.of(context).pop<String>(_selectedChatRoomId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: const CommonAppBar(title: '교환 요청', showBottomBorder: true),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
                : ListView(
                    children: [
                      _buildItemCard(),
                      SizedBox(height: 48.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                        child: Text('교환 상대를 선택해주세요', style: CustomTextStyles.h2.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      SizedBox(height: 16.h),
                      if (_chatRooms.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 48.h),
                          child: Center(
                            child: Text(
                              '채팅 상대가 없습니다.',
                              style: CustomTextStyles.p1.copyWith(color: AppColors.opacity40White),
                            ),
                          ),
                        )
                      else
                        ..._chatRooms.map(_buildPartnerRow),
                      SizedBox(height: 24.h),
                    ],
                  ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 63.h + MediaQuery.of(context).padding.bottom),
            child: CompletionButton(
              isEnabled: _selectedChatRoomId != null,
              buttonText: '전송하기',
              isLoading: false,
              enabledOnPressed: _onConfirm,
            ),
          ),
        ],
      ),
    );
  }

  /// 상단 물품 정보 카드
  Widget _buildItemCard() {
    final imageUrl = widget.item.primaryImageUrl;
    final itemName = widget.item.itemName ?? '물품명 없음';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
      child: TradeRequestTargetPreview(
        imageUrl: imageUrl,
        itemName: itemName,
        tags: itemTagLabels(condition: widget.item.itemCondition, tradeOptions: widget.item.itemTradeOptions),
        backgroundColor: AppColors.secondaryBlack1,
      ),
    );
  }

  /// 교환 상대 선택 행
  Widget _buildPartnerRow(ChatRoomDetailDto room) {
    final isSelected = _selectedChatRoomId == room.chatRoomId;
    final member = room.targetMember;
    final nickname = member?.nickname ?? '알 수 없음';
    final location = room.targetMemberEupMyeonDong ?? '';
    final timeAgo = room.lastMessageTime != null ? getTimeAgo(room.lastMessageTime!) : '';
    final messagePreview = room.lastMessageContent ?? '';

    return GestureDetector(
      onTap: () {
        if (room.chatRoomId == null) return;
        setState(() => _selectedChatRoomId = isSelected ? null : room.chatRoomId);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h, left: 12.w, right: 12.w),
        padding: EdgeInsets.only(bottom: 14.h, left: 16.w, top: 16.h, right: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryYellow.withValues(alpha: 0.1) : AppColors.primaryBlack,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryYellow.withValues(alpha: 0.3) : AppColors.transparent,
            width: 1.w,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          children: [
            // 물품 이미지 + 프로필 오버레이
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: 48.w,
                  height: 48.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: room.targetItemImageUrl != null
                        ? CachedImage(
                            imageUrl: room.targetItemImageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: Container(color: AppColors.imagePlaceholderBackground),
                          )
                        : Container(color: AppColors.imagePlaceholderBackground),
                  ),
                ),
                Positioned(
                  right: -4.w,
                  bottom: -4.h,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.secondaryBlack1, width: 2.w),
                    ),
                    child: UserProfileCircularAvatar(
                      avatarSize: Size(22.w, 22.w),
                      profileUrl: member?.profileUrl,
                      hasBorder: false,
                      isDeleteAccount: false,
                    ),
                  ),
                ),
              ],
            ),

            // 가로 간격
            SizedBox(width: 10.w),

            // 닉네임 + 위치 + 시간 + 채팅내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nickname,
                          style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (location.isNotEmpty || timeAgo.isNotEmpty) ...[
                        SizedBox(width: 8.w),
                        Text(
                          location,
                          style: CustomTextStyles.p3.copyWith(
                            color: AppColors.chatLocationTimeMessage,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          width: 2.w,
                          height: 2.w,
                          margin: EdgeInsets.symmetric(horizontal: 2.w),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.chatLocationTimeMessage,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: CustomTextStyles.p3.copyWith(
                            color: AppColors.chatLocationTimeMessage,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  if (messagePreview.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      messagePreview,
                      style: CustomTextStyles.p2.copyWith(
                        color: AppColors.chatLocationTimeMessage,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
