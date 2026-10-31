import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:romrom_fe/debug/log_capture.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 디버그 로그 뷰어 공통 패널: 드래그 이동, 우하단 리사이즈, 제목 표시줄, 검색, 복사·클리어
/// 로그 출처(앱 로그·서버 로그)는 [readLogs]·[logStream]·[clearLogs]로 주입
class DebugLogViewerPanel extends StatefulWidget {
  final String title;
  // 로그 0건일 때 가운데 문구
  final String emptyLogText;
  // 현재 버퍼 로그 목록 조회
  final List<CapturedLog> Function() readLogs;
  // 새 로그 실시간 스트림
  final Stream<CapturedLog> logStream;
  final VoidCallback clearLogs;
  // 제목 표시줄 추가 버튼 생성 (필터 버튼 앞, 패널 rebuild마다 호출 > 연결 상태 등 최신 값 반영)
  final List<Widget> Function()? buildTitleBarActions;
  final VoidCallback onClose;
  final VoidCallback onMinimize;

  const DebugLogViewerPanel({
    super.key,
    required this.title,
    required this.emptyLogText,
    required this.readLogs,
    required this.logStream,
    required this.clearLogs,
    this.buildTitleBarActions,
    required this.onClose,
    required this.onMinimize,
  });

  @override
  State<DebugLogViewerPanel> createState() => _DebugLogViewerPanelState();
}

class _DebugLogViewerPanelState extends State<DebugLogViewerPanel> {
  // 패널 위치/크기 (첫 build에서 화면 비율로 크기 초기화)
  double _x = 16;
  double _y = 80;
  double _width = 360;
  double _height = 400;
  bool _isSizeInitialized = false;
  // 리사이즈 최소 크기 (px)
  static const double _minimumWidth = 280;
  static const double _minimumHeight = 200;
  // 첫 크기 상한 (px)
  static const double _initialMaximumWidth = 500;
  static const double _initialMaximumHeight = 600;

  // 로그 데이터
  StreamSubscription<CapturedLog>? _subscription;
  // 로그 갱신 디바운스 시간
  static const Duration _debounceDelay = Duration(milliseconds: 100);
  Timer? _debounceTimer;
  List<CapturedLog> _filteredLogs = [];

  // 필터 상태
  String _searchQuery = '';
  bool _isAutoScrollEnabled = true;
  bool _shouldShowCopiedFeedback = false;

  // 컨트롤러
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // 필터 영역 표시 여부
  bool _isFilterBarVisible = true;

  @override
  void initState() {
    super.initState();
    _applyFilters();

    _subscription = widget.logStream.listen((log) {
      // 디바운스: 빈번한 로그 유입 시 UI 업데이트 최적화
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDelay, () {
        _applyFilters();
        if (_isAutoScrollEnabled && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      _filteredLogs = widget.readLogs().where((log) {
        if (_searchQuery.isNotEmpty) {
          final message = log.message.toLowerCase();
          final query = _searchQuery.toLowerCase();
          if (!message.contains(query)) return false;
        }
        return true;
      }).toList();
    });
  }

  void _clearLogs() {
    widget.clearLogs();
    _applyFilters();
  }

  Future<void> _copyLogs() async {
    final text = _filteredLogs.map((log) => '${_formatLogTime(log.time)} ${log.message}').join('\n');
    try {
      // 클립보드 쓰기 완료 후 피드백 표시 (await 없으면 복사 전에 UI 업데이트됨)
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      setState(() => _shouldShowCopiedFeedback = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _shouldShowCopiedFeedback = false);
      });
    } catch (_) {
      // 복사 실패 시 피드백 없이 조용히 종료
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 첫 크기: 화면 너비 90%·높이 50%
    if (!_isSizeInitialized) {
      _width = (screenSize.width * 0.9).clamp(_minimumWidth, _initialMaximumWidth);
      _height = (screenSize.height * 0.5).clamp(_minimumHeight, _initialMaximumHeight);
      _isSizeInitialized = true;
    }

    return Positioned(
      left: _x,
      top: _y,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: AppColors.primaryBlack.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.secondaryBlack2, width: 1),
            boxShadow: const [BoxShadow(color: AppColors.debugPanelShadowStrong, blurRadius: 16, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              _buildTitleBar(screenSize),
              if (_isFilterBarVisible) _buildFilterBar(),
              Expanded(child: _buildLogList()),
              _buildBottomBar(),
              _buildResizeHandle(screenSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(Size screenSize) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _x = (_x + details.delta.dx).clamp(0, screenSize.width - _width);
          _y = (_y + details.delta.dy).clamp(0, screenSize.height - _height);
        });
      },
      child: Container(
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.secondaryBlack1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator, color: AppColors.debugTextDarkGray, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.title,
                style: CustomTextStyles.debugBase.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            ...?widget.buildTitleBarActions?.call(),
            DebugTitleBarButton(
              icon: _isFilterBarVisible ? Icons.filter_list : Icons.filter_list_off,
              onTap: () => setState(() => _isFilterBarVisible = !_isFilterBarVisible),
            ),
            DebugTitleBarButton(
              icon: _isAutoScrollEnabled ? Icons.vertical_align_bottom : Icons.pause,
              onTap: () => setState(() => _isAutoScrollEnabled = !_isAutoScrollEnabled),
            ),
            DebugTitleBarButton(icon: Icons.minimize, onTap: widget.onMinimize),
            DebugTitleBarButton(icon: Icons.close, onTap: widget.onClose),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.secondaryBlack2, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 28,
              child: TextField(
                controller: _searchController,
                style: CustomTextStyles.debugBase.copyWith(fontSize: 11),
                decoration: InputDecoration(
                  hintText: '검색...',
                  hintStyle: CustomTextStyles.debugBase.copyWith(color: AppColors.debugTextDarkGray, fontSize: 11),
                  prefixIcon: const Icon(Icons.search, size: 14, color: AppColors.debugTextDarkGray),
                  prefixIconConstraints: const BoxConstraints(minWidth: 28),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  filled: true,
                  fillColor: AppColors.secondaryBlack1,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _applyFilters();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    if (_filteredLogs.isEmpty) {
      return Center(
        child: Text(
          widget.emptyLogText,
          style: CustomTextStyles.debugBase.copyWith(color: AppColors.debugTextDarkGray),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        final time = _formatLogTime(log.time);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$time ',
                  style: CustomTextStyles.debugBase.copyWith(
                    color: AppColors.debugTextDarkGray,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
                TextSpan(
                  text: log.message,
                  style: CustomTextStyles.debugBase.copyWith(fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.secondaryBlack2, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _clearLogs,
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 14, color: AppColors.debugTextGray),
                const SizedBox(width: 4),
                Text('클리어', style: CustomTextStyles.debugBase.copyWith(color: AppColors.debugTextGray, fontSize: 11)),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredLogs.length}건',
            style: CustomTextStyles.debugBase.copyWith(color: AppColors.debugTextDarkGray, fontSize: 11),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _copyLogs,
            child: Row(
              children: [
                Icon(
                  Icons.copy,
                  size: 14,
                  color: _shouldShowCopiedFeedback ? AppColors.primaryYellow : AppColors.debugTextGray,
                ),
                const SizedBox(width: 4),
                Text(
                  _shouldShowCopiedFeedback ? '복사됨!' : '복사',
                  style: CustomTextStyles.debugBase.copyWith(
                    color: _shouldShowCopiedFeedback ? AppColors.primaryYellow : AppColors.debugTextGray,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResizeHandle(Size screenSize) {
    return Align(
      alignment: Alignment.bottomRight,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _width = (_width + details.delta.dx).clamp(_minimumWidth, screenSize.width - _x);
            _height = (_height + details.delta.dy).clamp(_minimumHeight, screenSize.height - _y);
          });
        },
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.bottomRight,
          child: const Icon(Icons.drag_handle, size: 14, color: AppColors.debugTextDarkGray),
        ),
      ),
    );
  }

  /// 로그 시각 > 'HH:mm:ss'
  String _formatLogTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}

/// 제목 표시줄 아이콘 버튼 (16px, 기본 회색 — [color]로 강조색 지정)
class DebugTitleBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const DebugTitleBarButton({super.key, required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: color ?? AppColors.debugTextGray, size: 16),
      ),
    );
  }
}
