import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/context_menu_enums.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = Platform.isIOS ? 8.h + MediaQuery.of(context).padding.bottom : 21.h;
    final bool sendDisabled = !hasText || isInputDisabled || isSendingMessage;

    return Container(
      padding: EdgeInsets.only(top: 8.h, left: 16.w, bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 40.h <= inputFieldHeight && inputFieldHeight <= 70.h ? inputFieldHeight : 40.h,
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(100.r), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  suffixIcon: TextFieldTapRegion(
                    child: AppPressable(
                      onTap: sendDisabled ? null : onSend,
                      scaleDown: AppPressable.scaleIcon,
                      enableRipple: false,
                      child: Container(
                        margin: EdgeInsets.all(4.w),
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
                  suffixIconConstraints: BoxConstraints(
                    minWidth: 40.w,
                    minHeight: 40.w,
                    maxWidth: 40.w,
                    maxHeight: 40.w,
                  ),
                ),
                onSubmitted: sendDisabled ? null : (_) => onSend(),
              ),
            ),
          ),
          SizedBox(width: 16.w),
        ],
      ),
    );
  }
}
