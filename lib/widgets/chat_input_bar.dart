import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/context_menu_enums.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';

/// 채팅방 하단 메시지 입력 바
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isInputDisabled;
  final bool isSendingMessage;
  final bool hasText;
  final double inputFieldHeight;
  final String hintText;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onSendLocation;
  final VoidCallback onRequestExchange;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isInputDisabled,
    required this.isSendingMessage,
    required this.hasText,
    required this.inputFieldHeight,
    required this.hintText,
    required this.onSend,
    required this.onPickImage,
    required this.onSendLocation,
    required this.onRequestExchange,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = Platform.isIOS ? 8.h + MediaQuery.of(context).padding.bottom : 21.h;
    final bool sendDisabled = !hasText || isInputDisabled || isSendingMessage;

    // 동적 라운드 계산: 1줄(캡슐형) → 여러 줄(20.r 둥근 사각형)
    final double minH = 40.h;
    final double maxH = 130.h;
    final double clampedHeight = inputFieldHeight.clamp(minH, maxH);
    final double t = maxH > minH ? ((clampedHeight - minH) / (maxH - minH)) : 0.0;
    final double borderRadius = lerpDouble(clampedHeight / 2, 20.r, t) ?? clampedHeight / 2;

    return Container(
      padding: EdgeInsets.only(top: 8.h, left: 16.w, bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // + 버튼 (하단 고정)
          Padding(
            padding: EdgeInsets.only(right: 8.0.w),
            child: SizedBox(
              width: 40.w,
              height: 40.w,
              child: IgnorePointer(
                ignoring: isInputDisabled,
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
                      onTap: () => onPickImage(),
                    ),
                    ContextMenuItem(
                      id: 'send_location',
                      icon: AppIcons.location,
                      iconColor: AppColors.opacity60White,
                      title: '위치 보내기',
                      onTap: () => onSendLocation(),
                    ),
                    ContextMenuItem(
                      id: 'request_exchange',
                      icon: AppIcons.change,
                      iconColor: AppColors.opacity60White,
                      title: '교환 완료 요청',
                      onTap: () => onRequestExchange(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 텍스트 입력 필드 (suffixIcon 제거)
          Expanded(
            child: SizedBox(
              height: clampedHeight,
              child: TextField(
                controller: controller,
                enabled: !isInputDisabled,
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
                  hintText: hintText,
                  hintStyle: CustomTextStyles.p2.copyWith(color: AppColors.opacity50White),
                  filled: true,
                  fillColor: AppColors.opacity10White,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
                onSubmitted: sendDisabled ? null : (_) => onSend(),
              ),
            ),
          ),
          // 전송 버튼 (Row 자식으로 분리, 하단 고정)
          Padding(
            padding: EdgeInsets.only(left: 4.w, right: 16.w),
            child: SizedBox(
              width: 40.w,
              height: 40.w,
              child: Material(
                color: Colors.transparent,
                child: ClipOval(
                  child: InkWell(
                    onTap: sendDisabled ? null : onSend,
                    customBorder: const CircleBorder(),
                    highlightColor: AppColors.buttonHighlightColorGray,
                    splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: sendDisabled ? AppColors.secondaryBlack2 : AppColors.primaryYellow,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          AppIcons.arrowUpward,
                          color: sendDisabled ? AppColors.secondaryBlack1 : AppColors.primaryBlack,
                          size: 32.w,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
