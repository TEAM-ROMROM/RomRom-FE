import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/coach_mark/pages/coach_mark_page1.dart';
import 'package:romrom_fe/widgets/coach_mark/pages/coach_mark_page2.dart';
import 'package:romrom_fe/widgets/coach_mark/pages/coach_mark_page3.dart';
import 'package:romrom_fe/widgets/coach_mark/pages/coach_mark_page4.dart';
import 'package:romrom_fe/widgets/coach_mark/pages/coach_mark_page5.dart';

/// 코치마크 전체 오버레이 위젯
/// home_tab_screen.dart의 _buildCoachMarkOverlay를 대체
class CoachMarkOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const CoachMarkOverlay({super.key, required this.onClose});

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> {
  late final PageController _pageController;
  final ValueNotifier<int> _pageNotifier = ValueNotifier(0);
  static const int _pageCount = 5;

  final List<Widget> _pages = [
    const CoachMarkPage1(),
    const CoachMarkPage2(),
    const CoachMarkPage3(),
    const CoachMarkPage4(),
    const CoachMarkPage5(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageNotifier.dispose();
    super.dispose();
  }

  void _nextOrClose(int currentIndex) {
    if (currentIndex < _pageCount - 1) {
      _pageController.animateToPage(
        currentIndex + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.opacity70Black,
        child: SafeArea(
          child: Column(
            children: [
              // 닫기 버튼
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: AppColors.transparent,
                    child: InkWell(
                      onTap: widget.onClose,
                      customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('닫기', style: CustomTextStyles.p2),
                      ),
                    ),
                  ),
                ),
              ),
              // 페이지 콘텐츠
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: _pageNotifier,
                  builder: (context, page, child) => PageView.builder(
                    controller: _pageController,
                    itemCount: _pageCount,
                    onPageChanged: (p) => _pageNotifier.value = p,
                    itemBuilder: (context, index) =>
                        GestureDetector(onTap: () => _nextOrClose(index), child: _pages[index]),
                  ),
                ),
              ),
              // 페이지 인디케이터
              ValueListenableBuilder<int>(
                valueListenable: _pageNotifier,
                builder: (context, page, child) => Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageCount, (i) {
                      final isActive = i == page;
                      return GestureDetector(
                        onTap: () => _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primaryYellow : AppColors.opacity50White,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
