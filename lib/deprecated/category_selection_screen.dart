// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// import 'package:romrom_fe/enums/item_categories.dart';
// import 'package:romrom_fe/models/app_colors.dart';
// import 'package:romrom_fe/models/app_theme.dart';
// import 'package:romrom_fe/screens/main_screen.dart';
// import 'package:romrom_fe/services/apis/member_api.dart';
// import 'package:romrom_fe/utils/common_utils.dart';
// import 'package:romrom_fe/widgets/completion_button.dart';
// import 'package:romrom_fe/widgets/onboarding_progress_header.dart';
// import 'package:romrom_fe/widgets/onboarding_title_header.dart';
//
// class CategorySelectionScreen extends StatefulWidget {
//   const CategorySelectionScreen({super.key});
//
//   @override
//   State<CategorySelectionScreen> createState() =>
//       _CategorySelectionScreenState();
// }
//
// class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
//   final memberApi = MemberApi();
//   List<int> selectedCategories = [];
//
//   bool get isSelectedCategories => selectedCategories.isNotEmpty;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 상태표시줄 여백
//           SizedBox(height: MediaQuery.of(context).padding.top),
//
//           // 온보딩 프로그레스 헤더 : Step3
//           OnboardingProgressHeader(
//             currentStep: 3,
//             totalSteps: 3,
//             onBackPressed: () => Navigator.of(context).pop(),
//           ),
//
//           // 온보딩 제목 헤더
//           const OnboardingTitleHeader(
//             title: '카테고리 선택',
//             subtitle: '관심있는 분야를 선택해주세요!',
//           ),
//
//           // 카테고리 선택 영역
//           Expanded(
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 24.0.w),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(height: 32.h),
//                   // 카테고리 칩 표시
//                   Expanded(
//                     child: SingleChildScrollView(
//                       child: _buildCategoryChips(context),
//                     ),
//                   ),
//
//                   // 하단 버튼
//                   Padding(
//                     padding: EdgeInsets.only(bottom: 48.h),
//                     child: CategoryCompletionButton(
//                       isEnabled: isSelectedCategories,
//                       enabledOnPressed: () async {
//                         try {
//                           await memberApi
//                               .savePreferredCategories(selectedCategories);
//                           // 카테고리 선택 완료 후 홈화면 이동
//                           if (context.mounted) {
//                             Navigator.pushAndRemoveUntil(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) => const MainScreen()),
//                               (route) => false,
//                             );
//                           }
//                         } catch (e) {
//                           debugPrint("Error: $e");
//                           if (context.mounted) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('카테고리 저장에 실패했습니다. 다시 시도해주세요.'),
//                                 backgroundColor: Colors.red,
//                               ),
//                             );
//                           }
//                         }
//                       },
//                       buttonText: '완료',
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// 카테고리 선택 : choiceChip 빌드
//   Widget _buildCategoryChips(BuildContext context) {
//     return Wrap(
//       spacing: 8.0.w,
//       runSpacing: 12.0.h,
//       children: ItemCategories.values
//           .map((category) => _buildCategoryChip(context, category))
//           .toList(),
//     );
//   }
//
//   /// 카테고리 chip css
//   Widget _buildCategoryChip(BuildContext context, ItemCategories category) {
//     final bool isSelected = selectedCategories.contains(category.id);
//
//     return RawChip(
//       label: Text(
//         category.name,
//         style: CustomTextStyles.p2.copyWith(
//           fontSize: adjustedFontSize(context, 14.0),
//           color:
//               isSelected ? AppColors.textColorBlack : AppColors.textColorWhite,
//           wordSpacing: -0.32.w,
//         ),
//       ),
//       labelPadding: EdgeInsets.zero,
//       padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 10.0.h),
//       selected: isSelected,
//       selectedColor: AppColors.primaryYellow,
//       backgroundColor: AppColors.primaryBlack,
//       shape: RoundedRectangleBorder(
//         side: BorderSide(
//           color:
//               isSelected ? AppColors.primaryYellow : AppColors.textColorWhite,
//           strokeAlign: BorderSide.strokeAlignInside,
//           width: 1.0.w,
//         ),
//         borderRadius: BorderRadiusDirectional.circular(100.r),
//       ),
//       checkmarkColor: Colors.transparent,
//       showCheckmark: false,
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//       onSelected: (bool selected) =>
//           _toggleCategorySelection(category.id, selected),
//     );
//   }
//
//   /// 선택하면 categoryId 리스트 추가
//   void _toggleCategorySelection(int categoryId, bool isSelected) {
//     setState(() {
//       if (isSelected) {
//         selectedCategories.add(categoryId);
//       } else {
//         selectedCategories.remove(categoryId);
//       }
//       debugPrint("선택 카테고리 : $selectedCategories");
//     });
//   }
// }
