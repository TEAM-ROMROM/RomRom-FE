import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:romrom_fe/debug/log_capture.dart';
import 'package:romrom_fe/debug/server_log_client.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 서버 로그 뷰어 패널 (SSE 기반)
class DebugServerLogPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;

  const DebugServerLogPanel({super.key, required this.onClose, required this.onMinimize});

  @override
  State<DebugServerLogPanel> createState() => _DebugServerLogPanelState();
}

class _DebugServerLogPanelState extends State<DebugServerLogPanel> {
  // 패널 위치/크기
  double _x = 16;
  double _y = 80;
  double _width = 360;
  double _height = 400;
  bool _sizeInitialized = false;
  static const double _minWidth = 280;
  static const double _minHeight = 200;

  // 서버 로그 클라이언트
  final ServerLogClient _client = ServerLogClient();
  StreamSubscription<CapturedLog>? _subscription;
  Timer? _debounceTimer;
  List<CapturedLog> _filteredLogs = [];

  // 필터 상태
  String _searchQuery = '';
  bool _autoScroll = true;
  bool _showCopiedFeedback = false;

  // 컨트롤러
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // 필터 영역 표시 여부
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _client.connect();
    _applyFilters();

    _subscription = _client.stream.listen((log) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 100), () {
        _applyFilters();
        if (_autoScroll && mounted) {
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
    _client.disconnect();
    super.dispose();
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      _filteredLogs = _client.logs.where((log) {
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
    _client.clear();
    _applyFilters();
  }

  void _copyLogs() {
    final text = _filteredLogs
        .map((log) {
          final time =
              '${log.time.hour.toString().padLeft(2, '0')}:'
              '${log.time.minute.toString().padLeft(2, '0')}:'
              '${log.time.second.toString().padLeft(2, '0')}';
          return '$time ${log.message}';
        })
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _showCopiedFeedback = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showCopiedFeedback = false);
    });
  }

  void _toggleConnection() {
    if (_client.isConnected) {
      _client.disconnect();
    } else {
      _client.connect();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (!_sizeInitialized) {
      _width = (screenSize.width * 0.9).clamp(_minWidth, 500);
      _height = (screenSize.height * 0.5).clamp(_minHeight, 600);
      _sizeInitialized = true;
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
            boxShadow: const [BoxShadow(color: Color(0x60000000), blurRadius: 16, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              _buildTitleBar(screenSize),
              if (_showFilters) _buildFilterBar(),
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
            const Icon(Icons.drag_indicator, color: Color(0xFF888888), size: 16),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                '서버 로그',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            // 연결 상태 표시
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _client.isConnected ? Colors.green : Colors.red),
            ),
            const SizedBox(width: 4),
            _titleBarButton(icon: _client.isConnected ? Icons.link : Icons.link_off, onTap: _toggleConnection),
            _titleBarButton(
              icon: _showFilters ? Icons.filter_list : Icons.filter_list_off,
              onTap: () => setState(() => _showFilters = !_showFilters),
            ),
            _titleBarButton(
              icon: _autoScroll ? Icons.vertical_align_bottom : Icons.pause,
              onTap: () => setState(() => _autoScroll = !_autoScroll),
            ),
            _titleBarButton(icon: Icons.minimize, onTap: widget.onMinimize),
            _titleBarButton(icon: Icons.close, onTap: widget.onClose),
          ],
        ),
      ),
    );
  }

  Widget _titleBarButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: const Color(0xFFCCCCCC), size: 16),
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
                style: const TextStyle(color: Colors.white, fontSize: 11),
                decoration: InputDecoration(
                  hintText: '검색...',
                  hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                  prefixIcon: const Icon(Icons.search, size: 14, color: Color(0xFF888888)),
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
      return const Center(
        child: Text('서버 로그 없음', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        final time =
            '${log.time.hour.toString().padLeft(2, '0')}:'
            '${log.time.minute.toString().padLeft(2, '0')}:'
            '${log.time.second.toString().padLeft(2, '0')}';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$time ',
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 10, fontFamily: 'monospace'),
                ),
                TextSpan(
                  text: log.message,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
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
            child: const Row(
              children: [
                Icon(Icons.delete_outline, size: 14, color: Color(0xFFCCCCCC)),
                SizedBox(width: 4),
                Text('클리어', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 11)),
              ],
            ),
          ),
          const Spacer(),
          Text('${_filteredLogs.length}건', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
          const Spacer(),
          GestureDetector(
            onTap: _copyLogs,
            child: Row(
              children: [
                Icon(
                  Icons.copy,
                  size: 14,
                  color: _showCopiedFeedback ? AppColors.primaryYellow : const Color(0xFFCCCCCC),
                ),
                const SizedBox(width: 4),
                Text(
                  _showCopiedFeedback ? '복사됨!' : '복사',
                  style: TextStyle(
                    color: _showCopiedFeedback ? AppColors.primaryYellow : const Color(0xFFCCCCCC),
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
            _width = (_width + details.delta.dx).clamp(_minWidth, screenSize.width - _x);
            _height = (_height + details.delta.dy).clamp(_minHeight, screenSize.height - _y);
          });
        },
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.bottomRight,
          child: const Icon(Icons.drag_handle, size: 14, color: Color(0xFF888888)),
        ),
      ),
    );
  }
}
