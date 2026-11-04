// 채팅방 상단 '연결 중…' 띠: 소켓 끊김이 잠깐 이상 이어질 때만 노출, 연결되면 숨김 (짧은 재연결 깜빡임 방지)
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

class ChatConnectionBanner extends StatefulWidget {
  // 소켓 연결 상태 (true 연결, false 끊김·재연결 대기)
  final ValueListenable<bool> connectionStatus;

  const ChatConnectionBanner({super.key, required this.connectionStatus});

  // 끊김 후 띠 노출까지 대기 (진입 직후 연결·순간 재연결은 표시 안 함)
  static const Duration disconnectedGraceDuration = Duration(seconds: 1);

  @override
  State<ChatConnectionBanner> createState() => _ChatConnectionBannerState();
}

class _ChatConnectionBannerState extends State<ChatConnectionBanner> {
  bool _isBannerVisible = false;
  Timer? _graceTimer;

  @override
  void initState() {
    super.initState();
    widget.connectionStatus.addListener(_onConnectionStatusChanged);
    _onConnectionStatusChanged();
  }

  @override
  void didUpdateWidget(covariant ChatConnectionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connectionStatus == widget.connectionStatus) return;
    oldWidget.connectionStatus.removeListener(_onConnectionStatusChanged);
    widget.connectionStatus.addListener(_onConnectionStatusChanged);
    _onConnectionStatusChanged();
  }

  /// 연결 > 즉시 숨김, 끊김 > 대기 후 노출 (대기 중 연결되면 취소)
  void _onConnectionStatusChanged() {
    if (widget.connectionStatus.value) {
      _graceTimer?.cancel();
      _graceTimer = null;
      if (_isBannerVisible) setState(() => _isBannerVisible = false);
      return;
    }
    if (_isBannerVisible || _graceTimer != null) return;
    _graceTimer = Timer(ChatConnectionBanner.disconnectedGraceDuration, () {
      _graceTimer = null;
      if (mounted && !widget.connectionStatus.value) setState(() => _isBannerVisible = true);
    });
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    widget.connectionStatus.removeListener(_onConnectionStatusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: _isBannerVisible ? _buildBanner() : const SizedBox(width: double.infinity),
    );
  }

  /// 띠: 작은 로딩 > '연결 중…' (고정 px 여백, iPad 확대 방지)
  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.secondaryBlack1,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CommonLoadingIndicator.white(size: 12),
          const SizedBox(width: 8),
          Text(
            '연결 중…',
            style: CustomTextStyles.p3.copyWith(color: AppColors.opacity80White, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
