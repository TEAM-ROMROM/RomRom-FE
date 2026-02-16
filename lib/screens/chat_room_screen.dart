import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/context_menu_enums.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/services/apis/chat_api.dart';
import 'package:romrom_fe/services/apis/image_api.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/chat_websocket_service.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/chat_image_bubble.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/screens/profile/profile_screen.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;

  const ChatRoomScreen({super.key, required this.chatRoomId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatWebSocketService _wsService = ChatWebSocketService();
  final TextEditingController _messageController = TextEditingController();
  bool _hasText = false;
  double _inputFieldHeight = 40.0.h;

  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  StreamSubscription<ChatMessage>? _messageSubscription;

  // 낙관적 로컬 메시지(서버 응답 대기)
  final Map<String, ChatMessage> _pendingLocalMessages = {};

  ChatRoom chatRoom = ChatRoom();

  bool _isLoading = true;
  bool _hasError = false;
  bool _deleteModalShown = false;

  String _errorMessage = '';
  String? _myMemberId;

  // 이미지 관련 변수들
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // 입력 텍스트 변화에 따라 전송 버튼 색상/상태를 갱신하기 위한 리스너
    _messageController.addListener(_onMessageChanged);
  }

  bool _isLeaving = false;

  Future<void> _leaveRoom({required bool shouldPop}) async {
    if (_isLeaving) return; // 중복 방지
    _isLeaving = true;
    try {
      await ChatApi().updateChatRoomReadCursor(chatRoomId: widget.chatRoomId, isEntered: false);
    } catch (_) {
      // 실패해도 화면은 닫는다. 필요하면 로깅만
      debugPrint('채팅방 나가기 처리 실패');
    }
    if (shouldPop && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onMessageChanged() {
    final has = _messageController.text.trim().isNotEmpty;
    if (_hasText != has && mounted) {
      setState(() => _hasText = has);
    }

    // 동적 높이 계산
    if (mounted) {
      _updateInputFieldHeight();
    }
  }

  void _updateInputFieldHeight() {
    // 텍스트의 줄 수 계산
    final text = _messageController.text;
    final lineCount = '\n'.allMatches(text).length + 1;

    // 각 줄마다 대략 14.h 높이 추가 (최소 40.h, 최대 70.h)
    double newHeight = 40.h + ((lineCount - 1) * 14.h);
    newHeight = newHeight.clamp(40.h, 70.h);

    if (_inputFieldHeight != newHeight && mounted) {
      setState(() {
        _inputFieldHeight = newHeight;
      });
    }
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // 1. 현재 사용자 ID 가져오기
      _myMemberId = await MemberManager.getCurrentMemberId();

      if (_myMemberId == null) {
        throw Exception('사용자 정보를 불러올 수 없습니다');
      }

      // 2. WebSocket 연결
      await _wsService.connect();

      // 3. 과거 메시지 조회 (REST API)
      final chatApi = ChatApi();
      final response = await chatApi.getChatMessages(chatRoomId: widget.chatRoomId, pageNumber: 0, pageSize: 50);

      if (!mounted) return;

      setState(() {
        chatRoom = response.chatRoom!;
        _messages = response.messages?.content ?? [];
      });

      // 4. 실시간 메시지 구독 (WebSocket)
      _messageSubscription = _wsService.subscribeToChatRoom(widget.chatRoomId).listen((newMessage) {
        if (!mounted) return;

        setState(() {
          // 중복 서버 ID 체크
          final newId = newMessage.chatMessageId;
          final isDup = (newId != null) && _messages.any((m) => m.chatMessageId != null && m.chatMessageId == newId);
          if (isDup) {
            debugPrint('중복 메시지 수신 무시: chatMessageId=$newId');
            return;
          }

          // pending과 매칭 시도: 같은 발신자 + 동일 content + 시간 차 <= 10s
          String? matchedLocalId;
          _pendingLocalMessages.forEach((localId, localMsg) {
            if (matchedLocalId != null) return;
            if (localMsg.senderId != _myMemberId) return;
            if ((localMsg.content ?? '') != (newMessage.content ?? '')) {
              return;
            }
            final localDt = localMsg.createdDate ?? DateTime.now();
            final serverDt = newMessage.createdDate ?? DateTime.now();
            if (serverDt.difference(localDt).inSeconds.abs() <= 10) {
              matchedLocalId = localId;
            }
          });

          if (matchedLocalId != null) {
            final localMsg = _pendingLocalMessages.remove(matchedLocalId)!;
            final idx = _messages.indexWhere((m) => m.chatMessageId == localMsg.chatMessageId);

            // createdDate 보정
            final fixedServer = ChatMessage(
              chatRoomId: newMessage.chatRoomId ?? localMsg.chatRoomId,
              chatMessageId: newMessage.chatMessageId,
              senderId: newMessage.senderId ?? localMsg.senderId,

              // content도 서버가 빈 문자열로 주면 로컬 유지하는 게 안전
              content: (newMessage.content != null && newMessage.content!.trim().isNotEmpty)
                  ? newMessage.content
                  : localMsg.content,

              createdDate: newMessage.createdDate ?? localMsg.createdDate,
              type: newMessage.type ?? localMsg.type,
              imageUrls: (newMessage.imageUrls != null && newMessage.imageUrls!.isNotEmpty)
                  ? newMessage.imageUrls
                  : localMsg.imageUrls,
            );

            if (idx != -1) {
              _messages[idx] = fixedServer;
            } else {
              _messages.insert(0, fixedServer);
            }
          } else {
            _messages.insert(0, newMessage);
          }
        });

        _scrollToBottom();
      });

      setState(() => _isLoading = false);
      _scrollToBottom();
      chatApi.updateChatRoomReadCursor(chatRoomId: widget.chatRoomId, isEntered: true); // 입장 처리
      _showDeletedAccountModal(); // 탈퇴한 회원 모달 체크
    } catch (e) {
      debugPrint('채팅방 초기화 실패: $e');
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _errorMessage = ErrorUtils.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // 1) 로컬에 즉시 추가(낙관적 업데이트) 및 pending에 등록
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final localMsg = ChatMessage(
      chatRoomId: widget.chatRoomId,
      chatMessageId: localId,
      senderId: _myMemberId,
      content: content,
      createdDate: DateTime.now(),
    );
    setState(() {
      _messages.insert(0, localMsg);
      _pendingLocalMessages[localId] = localMsg;
    });
    _scrollToBottom();

    // 2) 서버로 전송 (가능하면 clientMessageId 전송하도록 서비스 확장 권장)
    _wsService.sendMessage(chatRoomId: widget.chatRoomId, content: content, type: MessageType.text);

    _messageController.clear();
  }

  /// 이미지 메시지 전송
  /// imageUrls: 서버에서 반환된 이미지 URL 리스트
  /// imageMessage: 사진과 함께 전송할 텍스트 메시지 (선택사항)
  Future<void> _sendImage({required List<String> imageUrls, String? imageMessage}) async {
    if (imageUrls.isEmpty) return;
    if (!mounted) return;

    // 1) 로컬에 즉시 추가(낙관적 업데이트) 및 pending에 등록
    final content = imageMessage ?? '사진을 보냈습니다.';
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final localMsg = ChatMessage(
      chatRoomId: widget.chatRoomId,
      chatMessageId: localId,
      senderId: _myMemberId,
      createdDate: DateTime.now(),
      content: content, // content 필드 필요
      type: MessageType.image,
      imageUrls: imageUrls,
    );
    setState(() {
      _messages.insert(0, localMsg);
      _pendingLocalMessages[localId] = localMsg;
    });
    _scrollToBottom();

    // 2) WebSocket을 통해 서버로 전송
    _wsService.sendMessage(
      chatRoomId: widget.chatRoomId,
      type: MessageType.image,
      content: imageMessage ?? '',
      imageUrls: imageUrls,
    );

    // 텍스트 입력필드 초기화
    _messageController.clear();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    }
  }

  /// 이미지 선택 후 전송
  Future<void> _onPickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);

      if (picked == null) {
        // 사용자가 선택을 취소함
        return;
      }

      try {
        // 1) 선택된 이미지를 서버에 업로드
        final uploadedImageUrls = await ImageApi().uploadImages([picked]);
        if (!mounted) return;

        // imageUrls가 비어있는 경우 처리 필요
        if (uploadedImageUrls.isEmpty) {
          CommonSnackBar.show(context: context, message: '이미지 업로드 실패', type: SnackBarType.error);
          return;
        }

        // 2) 업로드된 URL로 메시지 전송 (imageMessage는 입력필드의 텍스트 사용)
        final textMessage = _messageController.text.trim();
        await _sendImage(imageUrls: uploadedImageUrls, imageMessage: textMessage.isEmpty ? null : textMessage);
      } catch (e) {
        if (context.mounted) {
          CommonSnackBar.show(context: context, message: '이미지 전송에 실패했습니다: $e', type: SnackBarType.error);
        }
      }
    } catch (e) {
      if (context.mounted) {
        CommonSnackBar.show(context: context, message: '이미지 선택에 실패했습니다: $e', type: SnackBarType.error);
      }
    }
  }

  void _showDeletedAccountModal() {
    if (!mounted) return;
    if (_deleteModalShown) return;
    if (chatRoom.getOpponent(_myMemberId!)?.accountStatus != AccountStatus.deleteAccount.serverName) return;

    _deleteModalShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await CommonModal.error(
        context: context,
        message: '존재하지 않거나 탈퇴한 사용자입니다.',
        onConfirm: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      );
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    // 채팅방 구독 해제 (참조 카운팅으로 ChatTabScreen의 구독은 유지됨)
    if (chatRoom.chatRoomId != null) {
      _wsService.unsubscribeFromChatRoom(chatRoom.chatRoomId!);
    }
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppColors.primaryBlack,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlack,
          leading: IconButton(
            icon: const Icon(AppIcons.navigateBefore, color: AppColors.textColorWhite),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage,
                style: CustomTextStyles.p1.copyWith(color: AppColors.textColorWhite),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow),
                child: Text('다시 시도', style: CustomTextStyles.p2.copyWith(color: AppColors.primaryBlack)),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false, // 기본 pop 막기
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _leaveRoom(shouldPop: false);
        } else {
          _leaveRoom(shouldPop: true);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.primaryBlack,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildTradeInfoCard(),
              Expanded(child: _buildMessageList()),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // 앱바 빌더
  CommonAppBar _buildAppBar() {
    return CommonAppBar(
      title: chatRoom.getOpponentNickname(_myMemberId!),
      onTitleTap: () {
        final opponent = chatRoom.getOpponent(_myMemberId!);
        if (opponent?.memberId != null) {
          context.navigateTo(screen: ProfileScreen(memberId: opponent!.memberId!));
        }
      },
      onBackPressed: () {
        _leaveRoom(shouldPop: true);
      },
      showBottomBorder: true,
      titleWidgets: Padding(
        padding: EdgeInsets.only(top: 8.0.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              chatRoom.getOpponentNickname(_myMemberId!),
              style: CustomTextStyles.h3.copyWith(fontWeight: FontWeight.w600),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.chatInactiveStatus),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    getLastActivityTime(chatRoom),
                    style: CustomTextStyles.p2.copyWith(color: AppColors.opacity50White),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.0.w, bottom: 8.h),
          child: RomRomContextMenu(
            items: [
              ContextMenuItem(
                id: 'report',
                icon: AppIcons.report,
                title: '신고하기',
                onTap: () async {
                  // TODO : 신고하기 화면으로 이동
                },
                showDividerAfter: true,
              ),
              ContextMenuItem(
                id: 'block',
                icon: AppIcons.slashCircle,
                iconColor: AppColors.itemOptionsMenuRedIcon,
                title: '차단하기',
                textColor: AppColors.itemOptionsMenuRedText,
                onTap: () async {
                  await CommonModal.confirm(
                    context: context,
                    message: '상대방을 차단하시겠습니까?\n차단한 사용자는 설정에서 확인할 수 있습니다.',
                    cancelText: '취소',
                    confirmText: '차단',
                    onCancel: () {
                      Navigator.of(context).pop(); // 모달 닫기
                    },
                    onConfirm: () async {
                      final opponentId = chatRoom.getOpponent(_myMemberId!)?.memberId;
                      if (opponentId == null) {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          CommonSnackBar.show(
                            context: context,
                            type: SnackBarType.error,
                            message: '상대방 정보를 찾을 수 없습니다.',
                          );
                        }
                        return;
                      }
                      try {
                        await MemberApi().blockMember(opponentId);
                        if (context.mounted) {
                          Navigator.of(context).pop(true); // 모달 닫기
                        }
                        // 화면 닫을 때도 동일한 _leaveRoom 로직
                        if (context.mounted) {
                          await _leaveRoom(shouldPop: true);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop(); // 모달 닫기
                          CommonSnackBar.show(
                            context: context,
                            type: SnackBarType.error,
                            message: '회원 차단 실패: ${ErrorUtils.getErrorMessage(e)}',
                          );
                        }
                      }
                    },
                  );
                },
                showDividerAfter: true,
              ),
              ContextMenuItem(
                id: 'leave_chat_room',
                icon: AppIcons.chatOut,
                iconColor: AppColors.itemOptionsMenuRedIcon,
                title: '채팅방 나가기',
                textColor: AppColors.itemOptionsMenuRedText,
                onTap: () async {
                  await CommonModal.confirm(
                    context: context,
                    message: '정말로 채팅방을 나가시겠습니까?',
                    cancelText: '취소',
                    confirmText: '나가기',
                    onCancel: () {
                      Navigator.of(context).pop(); // 모달 닫기
                    },
                    onConfirm: () async {
                      try {
                        await ChatApi().deleteChatRoom(chatRoomId: chatRoom.chatRoomId!);
                        if (context.mounted) {
                          Navigator.of(context).pop(true); // 모달 닫기
                        }
                        // 화면 닫을 때도 동일한 _leaveRoom 로직
                        if (context.mounted) {
                          await _leaveRoom(shouldPop: true);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop(); // 모달 닫기
                          CommonSnackBar.show(
                            context: context,
                            message: '채팅방 나가기 실패: ${ErrorUtils.getErrorMessage(e)}',
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 거래 정보 카드 빌더
  Widget _buildTradeInfoCard() {
    // 내 아이템과 상대방 아이템 구분
    final targetItem = chatRoom.tradeRequestHistory?.takeItem.member?.memberId == _myMemberId
        ? chatRoom.tradeRequestHistory?.giveItem
        : chatRoom.tradeRequestHistory?.takeItem;
    final myItem = chatRoom.tradeRequestHistory?.takeItem.member?.memberId == _myMemberId
        ? chatRoom.tradeRequestHistory?.takeItem
        : chatRoom.tradeRequestHistory?.giveItem;

    return Container(
      padding: EdgeInsets.only(top: 8.h, bottom: 16.h, left: 16.w, right: 16.w),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlack,
        border: Border(bottom: BorderSide(color: AppColors.opacity10White, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // 화면 크기 가져오기
              final screenWidth = MediaQuery.of(context).size.width;
              final imageHeight = screenWidth; // 정사각형 이미지

              // context.navigateTo() 헬퍼 사용 (iOS 스와이프 백 지원)
              context.navigateTo(
                screen: ItemDetailDescriptionScreen(
                  itemId: targetItem?.itemId ?? '',
                  imageSize: Size(screenWidth, imageHeight),
                  currentImageIndex: 0,
                  heroTag: 'first_item_${targetItem?.itemId}',
                  isMyItem: false,
                  isRequestManagement: false,
                ),
              );
            },
            child: CachedImage(
              imageUrl: targetItem?.primaryImageUrl ?? '',
              width: 48.w,
              height: 48.w,
              borderRadius: BorderRadius.circular(8.r),
              errorWidget: const SizedBox.shrink(),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  targetItem?.itemName ?? '제목 없음',
                  style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 10.h),
                Text(
                  '${formatPrice(targetItem?.price ?? 0)}원',
                  style: CustomTextStyles.p1.copyWith(color: AppColors.opacity60White),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              // 화면 크기 가져오기
              final screenWidth = MediaQuery.of(context).size.width;
              final imageHeight = screenWidth; // 정사각형 이미지

              // context.navigateTo() 헬퍼 사용 (iOS 스와이프 백 지원)
              context.navigateTo(
                screen: ItemDetailDescriptionScreen(
                  itemId: myItem?.itemId ?? '',
                  imageSize: Size(screenWidth, imageHeight),
                  currentImageIndex: 0,
                  heroTag: 'first_item_${myItem?.itemId}',
                  isMyItem: true,
                  isRequestManagement: false,
                ),
              );
            },
            child: CachedImage(
              imageUrl: myItem?.itemImages?.first.imageUrl ?? '',
              width: 48.w,
              height: 48.w,
              borderRadius: BorderRadius.circular(8.r),
              errorWidget: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Text('메시지를 입력해보세요', style: CustomTextStyles.p2.copyWith(color: AppColors.opacity50White)),
      );
    }

    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine = message.senderId == _myMemberId;

        // 메시지 간격: 같은 사람이 연속으로 보낸 메시지면 8, 아니면 24
        final double topGap =
            (index < _messages.length - 1 && _messages[index].senderId == _messages[index + 1].senderId) ? 8.h : 24.h;

        // 같은 사람 연속 메시지일 때는 같은 '분'에 속한 메시지들 중
        // 가장 마지막(=가장 최신) 메시지에만 시간 표시
        // 리스트는 reverse: true 이므로 index == 0 이 가장 최신 메시지
        final bool showTime =
            (index == 0) ||
            (index > 0 &&
                (
                // 발신자가 바뀌면 시간 표시
                _messages[index].senderId != _messages[index - 1].senderId ||
                    // 같은 발신자라도 이전(더 최신) 메시지와 분 단위가 다르면 표시
                    !isSameMinute(_messages[index].createdDate, _messages[index - 1].createdDate)));

        return Padding(
          padding: EdgeInsets.only(top: topGap),
          child: Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start, // isMine에 따라 정렬 방향 변경
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                message.type == MessageType.image
                    ? chatImageBubble(context, message)
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        constraints: BoxConstraints(maxWidth: 264.w),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBlack1,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          message.content ?? '',
                          style: CustomTextStyles.p2.copyWith(
                            color: AppColors.textColorWhite,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                      ),
                if (showTime) ...[
                  SizedBox(width: 8.w),
                  Text(
                    formatMessageTime(message.createdDate),
                    style: CustomTextStyles.p3.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.opacity50White,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ] else ...[
                if (showTime) ...[
                  Text(
                    formatMessageTime(message.createdDate),
                    style: CustomTextStyles.p3.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.opacity50White,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                message.type == MessageType.image
                    ? chatImageBubble(context, message)
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        constraints: BoxConstraints(maxWidth: 264.w, maxHeight: 264.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          message.content ?? '',
                          style: CustomTextStyles.p2.copyWith(
                            color: AppColors.textColorBlack,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                      ),
              ],
            ],
          ),
        );
      },
    );
  }

  // 입력 바 빌더
  Widget _buildInputBar() {
    double textFieldBottomPadding = Platform.isIOS ? 8.h + MediaQuery.of(context).padding.bottom : 21.h;

    return Container(
      padding: EdgeInsets.only(top: 8.w, left: 16.h, bottom: textFieldBottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 8.0.w),
            child: SizedBox(
              width: 40.w,
              height: 40.w,
              child: RomRomContextMenu(
                position: ContextMenuPosition.above,
                triggerRotationDegreesOnOpen: 45,
                customTrigger: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: const BoxDecoration(color: AppColors.secondaryBlack1, shape: BoxShape.circle),
                  child: Icon(AppIcons.addItemPlus, color: AppColors.textColorWhite, size: 20.sp),
                ),
                items: [
                  ContextMenuItem(
                    id: 'select_photo',
                    icon: AppIcons.chatImage,
                    iconColor: AppColors.opacity60White,
                    title: '사진 선택하기',
                    onTap: () {
                      _onPickImage();
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 40.h <= _inputFieldHeight && _inputFieldHeight <= 70.h ? _inputFieldHeight : 40.h,
              child: TextField(
                controller: _messageController,
                style: CustomTextStyles.p2.copyWith(
                  color: AppColors.textColorWhite,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                minLines: 1,
                maxLines: 5,
                cursorHeight: 16.h,
                cursorColor: AppColors.primaryYellow,
                cursorWidth: 1.5.w,
                decoration: InputDecoration(
                  hintText: '메세지를 입력하세요',
                  hintStyle: CustomTextStyles.p2.copyWith(color: AppColors.opacity50White),
                  filled: true,
                  fillColor: AppColors.opacity10White,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(100.r), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  // 텍스트 유무에 따라 버튼/아이콘 색상 및 활성화 상태 변경
                  suffixIcon: TextFieldTapRegion(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _messageController.text.trim().isEmpty
                          ? null
                          : () {
                              _sendMessage();
                            },
                      child: Container(
                        margin: EdgeInsets.all(4.w),
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: !_hasText ? AppColors.secondaryBlack2 : AppColors.primaryYellow,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            AppIcons.arrowUpward,
                            color: !_hasText ? AppColors.secondaryBlack1 : AppColors.primaryBlack,
                            size: 32.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  suffixIconConstraints: BoxConstraints(
                    minWidth: 40.w,
                    minHeight: 40.w,
                    maxWidth: 40.w,
                    maxHeight: 40.w,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 16.w),
        ],
      ),
    );
  }
}
