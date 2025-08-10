import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/scrollable_header.dart';
import 'package:romrom_fe/widgets/common/toggle_header_delegate.dart';
import 'package:romrom_fe/widgets/common/toggle_selector.dart';

class RequestManagementTabScreen extends StatefulWidget {
  const RequestManagementTabScreen({super.key});

  @override
  State<RequestManagementTabScreen> createState() =>
      _RequestManagementTabScreenState();
}

class _RequestManagementTabScreenState extends State<RequestManagementTabScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // 토글 상태 (false: 받은 요청, true: 보낸 요청)
  bool _isRightSelected = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  /// 토글 상태 변경
  void _onToggleChanged(bool isRight) {
    setState(() {
      _isRightSelected = isRight;
    });
    
    // TODO: 필터링된 데이터 로드 로직 추가
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: null,
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // 스크롤 가능한 헤더
            ScrollableHeader(
              title: '요청 관리',
              isScrolled: innerBoxIsScrolled || _isScrolled,
            ),
            // 토글 위젯을 고정 헤더로 추가
            SliverPersistentHeader(
              pinned: true,
              delegate: ToggleHeaderDelegate(
                child: ToggleSelector(
                  leftText: '받은 요청',
                  rightText: '보낸 요청',
                  isRightSelected: _isRightSelected,
                  onToggleChanged: _onToggleChanged,
                ),
              ),
            ),
          ],
          body: _buildContent(),
        ),
      ),
    );
  }

  /// 메인 컨텐츠 영역 구성
  Widget _buildContent() {
    // TODO: 실제 데이터 로드 및 표시 구현
    return Center(
      child: Text(
        _isRightSelected ? '보낸 요청 내용' : '받은 요청 내용',
        style: CustomTextStyles.p1,
      ),
    );
  }
}