import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:romrom_fe/debug/runtime_url_manager.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';

class DebugUrlPanel extends StatefulWidget {
  final VoidCallback onClose;

  const DebugUrlPanel({super.key, required this.onClose});

  @override
  State<DebugUrlPanel> createState() => _DebugUrlPanelState();
}

class _DebugUrlPanelState extends State<DebugUrlPanel> {
  double _x = 16;
  double _y = 80;
  static const double _panelWidth = 320;

  final TextEditingController _controller = TextEditingController();
  String _currentUrl = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = RuntimeUrlManager().baseUrl;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    setState(() => _isLoading = true);
    final url = RuntimeUrlManager.buildPreviewUrl(input);
    await RuntimeUrlManager().setBaseUrl(url);
    await _logoutAndNavigate();
  }

  Future<void> _resetToProd() async {
    setState(() => _isLoading = true);
    await RuntimeUrlManager().resetToDefault();
    await _logoutAndNavigate();
  }

  /// URL 변경 후 토큰 초기화 + 로그인 화면으로 이동
  /// PR 서버는 별도 DB라 기존 토큰이 유효하지 않으므로 재로그인 필요
  Future<void> _logoutAndNavigate() async {
    await TokenManager().deleteTokens();
    if (mounted) {
      widget.onClose();
      context.navigateTo(screen: const LoginScreen(), type: NavigationTypes.pushAndRemoveUntil);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _x,
      top: _y,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _x = (_x + details.delta.dx).clamp(0.0, screenSize.width - _panelWidth);
              _y = (_y + details.delta.dy).clamp(0.0, screenSize.height - 200.0);
            });
          },
          child: Container(
            width: _panelWidth,
            decoration: BoxDecoration(
              color: AppColors.primaryBlack.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondaryBlack2, width: 1),
              boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const Divider(color: Color(0xFF333333), height: 1),
                _buildCurrentUrl(),
                const Divider(color: Color(0xFF333333), height: 1),
                _buildInputSection(),
                const SizedBox(height: 8),
                _buildResetButton(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.dns, color: AppColors.primaryYellow, size: 16),
          const SizedBox(width: 8),
          const Text(
            '서버 URL 변경',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onClose,
            child: const Icon(Icons.close, color: AppColors.secondaryBlack2, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUrl() {
    final isProd = RuntimeUrlManager().isUsingProd;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('현재 연결', style: TextStyle(color: AppColors.secondaryBlack2, fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isProd ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _currentUrl,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PR / Issue 번호 입력', style: TextStyle(color: AppColors.secondaryBlack2, fontSize: 11)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.secondaryBlack2, width: 1),
                  ),
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: '예: 582',
                      hintStyle: TextStyle(color: Color(0xFF555555), fontSize: 13),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _connect(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isLoading ? null : _connect,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: AppColors.primaryYellow, borderRadius: BorderRadius.circular(6)),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text(
                            '연결',
                            style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'http://romrom-pr-{번호}.pr.suhsaechan.kr:8079',
            style: TextStyle(color: Color(0xFF555555), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _isLoading ? null : _resetToProd,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.secondaryBlack2, width: 1),
          ),
          child: Center(
            child: Text(
              'Prod로 초기화',
              style: TextStyle(
                color: RuntimeUrlManager().isUsingProd ? AppColors.secondaryBlack2 : Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
