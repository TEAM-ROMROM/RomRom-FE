import 'package:flutter/material.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 알림 카테고리 enum
enum NotificationCategory {
  exchangeRequest, // 교환 요청
  like, // 좋아요
  chat, // 채팅
  announcement, // 공지사항
}

/// 알림 카테고리 확장
extension NotificationCategoryExtension on NotificationCategory {
  String get label {
    switch (this) {
      case NotificationCategory.exchangeRequest:
        return '교환 요청';
      case NotificationCategory.like:
        return '좋아요';
      case NotificationCategory.chat:
        return '채팅';
      case NotificationCategory.announcement:
        return '공지사항';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationCategory.exchangeRequest:
        return AppIcons.exchange;
      case NotificationCategory.like:
        return AppIcons.itemRegisterHeart;
      case NotificationCategory.chat:
        return AppIcons.chat;
      case NotificationCategory.announcement:
        return AppIcons.bell;
    }
  }

  Color get iconColor {
    switch (this) {
      case NotificationCategory.exchangeRequest:
        return AppColors.primaryYellow;
      case NotificationCategory.like:
        return AppColors.notificationLikeHeart;
      case NotificationCategory.chat:
        return AppColors.primaryYellow;
      case NotificationCategory.announcement:
        return AppColors.primaryYellow;
    }
  }
}
