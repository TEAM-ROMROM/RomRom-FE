import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/trade_complete_partner_selection.dart';
import 'package:romrom_fe/providers/chat_repository_provider.dart';
import 'package:romrom_fe/utils/item_label_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/trade/trade_partner_row.dart';
import 'package:romrom_fe/widgets/trade_request_target_preview.dart';
import 'package:romrom_fe/widgets/skeletons/trade_partner_select_skeleton.dart';

/// 교환 완료 처리 시 교환 상대를 선택하는 화면
/// 결과: 채팅 상대(채팅방 ID) 또는 앱 밖에서 교환 (`TradeCompletePartnerSelection`), 닫으면 null
class TradeCompletePartnerSelectScreen extends ConsumerStatefulWidget {
  final Item item;

  const TradeCompletePartnerSelectScreen({super.key, required this.item});

  @override
  ConsumerState<TradeCompletePartnerSelectScreen> createState() => _TradeCompletePartnerSelectScreenState();
}

class _TradeCompletePartnerSelectScreenState extends ConsumerState<TradeCompletePartnerSelectScreen> {
  bool _isLoading = true;
  // 채팅 상대 목록 조회 실패 (빈 목록 안내 대신 다시 시도)
  bool _hasLoadError = false;
  bool _isRetrying = false;
  List<ChatRoomDetailDto> _chatRooms = [];
  String? _selectedChatRoomId;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  /// 물품 ID로 채팅방 목록 불러오기 (실패 시 다시 시도 뷰)
  Future<void> _loadChatRooms() async {
    final itemId = widget.item.itemId;
    if (itemId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await ref.read(chatRepositoryProvider).getChatRoomsByItemId(itemId: itemId);
      if (mounted) {
        setState(() {
          _chatRooms = result.content;
          _hasLoadError = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[TradePartnerSelect] chat rooms load failed: $e');
      if (mounted) {
        setState(() {
          _hasLoadError = true;
          _isLoading = false;
        });
      }
    }
  }

  /// 다시 시도: 진행 중이면 무시 > 재조회
  Future<void> _onRetryPressed() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      await _loadChatRooms();
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  /// 전송하기: 선택한 채팅 상대 결과 반환 (호출부가 채팅방 이동 > 교환 완료 요청)
  void _onConfirm() {
    final selectedChatRoomId = _selectedChatRoomId;
    if (selectedChatRoomId == null) return;
    Navigator.of(context).pop(TradeCompletePartnerSelection.chatPartner(chatRoomId: selectedChatRoomId));
  }

  /// 앱 밖에서 교환: 확인 모달 > 결과 반환 (등록 탭이 물품 상태를 교환 완료로 변경)
  Future<void> _onCompletedOutsideAppPressed() async {
    final bool? isConfirmed = await CommonModal.confirm(
      context: context,
      message: '채팅 없이 교환 완료로 바꿀까요?\n이 경우 후기는 남길 수 없어요.',
      confirmText: '교환 완료',
      confirmButtonColor: AppColors.primaryYellow,
      confirmTextColor: AppColors.textColorBlack,
      iconColor: AppColors.primaryYellow,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
    if (isConfirmed != true || !mounted) return;
    Navigator.of(context).pop(const TradeCompletePartnerSelection.outsideApp());
  }

  bool _isDeletedPartner(ChatRoomDetailDto room) =>
      room.targetMember?.accountStatus == AccountStatus.deleteAccount.serverName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: const CommonAppBar(title: '교환 요청', showBottomBorder: true),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const TradePartnerSelectSkeleton()
                : _hasLoadError
                ? EmptyStateView.error(
                    centerText: '채팅 상대를 불러오지 못했어요',
                    onRetry: _onRetryPressed,
                    isRetrying: _isRetrying,
                  )
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOutsideAppTradeLink(),
                const SizedBox(height: 12),
                CompletionButton(
                  isEnabled: _selectedChatRoomId != null,
                  buttonText: '전송하기',
                  isLoading: false,
                  enabledOnPressed: _onConfirm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// '채팅 없이 교환했어요' 링크 (채팅 상대 없음·탈퇴·조회 실패 시에도 교환 완료 가능)
  Widget _buildOutsideAppTradeLink() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onCompletedOutsideAppPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '채팅 없이 앱 밖에서 교환했어요',
          style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White, decoration: TextDecoration.underline),
        ),
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

  /// 교환 상대 선택 행 (탈퇴 상대는 흐리게 + 선택 불가 안내)
  Widget _buildPartnerRow(ChatRoomDetailDto room) {
    final isSelected = _selectedChatRoomId == room.chatRoomId;
    final isDeletedPartner = _isDeletedPartner(room);
    return GestureDetector(
      onTap: () {
        if (room.chatRoomId == null) return;
        if (isDeletedPartner) {
          CommonSnackBar.show(context: context, message: '탈퇴한 사용자에게는 교환 완료를 요청할 수 없어요', type: SnackBarType.info);
          return;
        }
        setState(() => _selectedChatRoomId = isSelected ? null : room.chatRoomId);
      },
      child: Opacity(
        // 탈퇴 상대 흐리게 (선택 불가 표시)
        opacity: isDeletedPartner ? 0.4 : 1,
        child: TradePartnerRow(room: room, isSelected: isSelected, isDeletedPartner: isDeletedPartner),
      ),
    );
  }
}
