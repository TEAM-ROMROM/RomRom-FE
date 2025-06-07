// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:http/http.dart' as http;
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_naver_map/flutter_naver_map.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:romrom_fe/enums/navigation_types.dart';
// import 'package:romrom_fe/icons/app_icons.dart';
// import 'package:romrom_fe/models/app_colors.dart';
// import 'package:romrom_fe/models/app_theme.dart';
// import 'package:romrom_fe/models/app_urls.dart';
// import 'package:romrom_fe/models/user_info.dart';
// import 'package:romrom_fe/screens/main_screen.dart';
// import 'package:romrom_fe/deprecated/category_selection_screen.dart';
// import 'package:romrom_fe/utils/common_utils.dart';
// import 'package:romrom_fe/models/apis/responses/naver_address_response.dart';
// import 'package:romrom_fe/services/apis/member_api.dart';
// import 'package:romrom_fe/widgets/onboarding_progress_header.dart';
// import 'package:romrom_fe/widgets/onboarding_title_header.dart';
//
// /// 위치 인증 화면
// class LocationVerificationScreen extends StatefulWidget {
//   const LocationVerificationScreen({super.key});
//
//   @override
//   State<LocationVerificationScreen> createState() => _LocationVerificationScreenState();
// }
//
// class _LocationVerificationScreenState extends State<LocationVerificationScreen> {
//   // 사용자의 현재 위치 좌표
//   NLatLng? _currentPosition;
//
//   // 현재 위치의 주소 정보 (동 단위)
//   String currentAdress = '';
//
//   // 위치 정보 저장
//   String siDo = '';
//   String siGunGu = '';
//   String eupMyoenDong = '';
//   String? ri;
//
//   // 네이버 맵 컨트롤러
//   final Completer<NaverMapController> mapControllerCompleter = Completer();
//
//   @override
//   void initState() {
//     super.initState();
//     _permission();
//   }
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
//           // 온보딩 프로그레스 헤더 (Step2)
//           OnboardingProgressHeader(
//             currentStep: 2,
//             totalSteps: 3,
//             onBackPressed: () => Navigator.of(context).pop(),
//           ),
//
//           // 온보딩 제목 헤더
//           const OnboardingTitleHeader(
//             title: '동네 인증하기',
//             subtitle: '내 위치를 인증해주세요',
//           ),
//
//           // 맵과 위치 정보 UI
//           _currentPosition == null
//               ? const Expanded(child: Center(child: CircularProgressIndicator()))
//               : Expanded(
//                   child: Column(
//                     children: [
//                       // 맵 영역
//                       Expanded(
//                         flex: 341,
//                         child: Stack(
//                           children: [
//                             NaverMap(
//                               options: NaverMapViewOptions(
//                                 initialCameraPosition: NCameraPosition(
//                                   target: _currentPosition!,
//                                   zoom: 15,
//                                 ),
//                                 logoAlign: NLogoAlign.leftBottom,
//                                 logoMargin: NEdgeInsets.fromEdgeInsets(
//                                   EdgeInsets.only(left: 24.w, bottom: 20.h),
//                                 ),
//                                 indoorEnable: true,
//                                 locationButtonEnable: false,
//                                 consumeSymbolTapEvents: false,
//                               ),
//                               forceGesture: false,
//                               onMapReady: (controller) async {
//                                 if (!mapControllerCompleter.isCompleted) {
//                                   mapControllerCompleter.complete(controller);
//                                 }
//                                 await getAddressByNaverApi(_currentPosition!);
//                                 await controller.setLocationTrackingMode(
//                                     NLocationTrackingMode.follow);
//                               },
//                             ),
//                             // 현재 위치 버튼
//                             Positioned(
//                               bottom: 48.h,
//                               left: 24.w,
//                               child: GestureDetector(
//                                 onTap: () async {
//                                   final controller = await mapControllerCompleter.future;
//                                   await controller.setLocationTrackingMode(
//                                       NLocationTrackingMode.follow);
//                                 },
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     color: AppColors.currentLocationButtonBg,
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                         color: AppColors.currentLocationButtonBorder,
//                                         width: 0.15.w,
//                                         strokeAlign: BorderSide.strokeAlignInside),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: AppColors.currentLocationButtonShadow
//                                             .withValues(alpha: 0.25),
//                                         blurRadius: 2.0,
//                                         offset: const Offset(0, 0),
//                                       ),
//                                       BoxShadow(
//                                         color: AppColors.currentLocationButtonShadow
//                                             .withValues(alpha: 0.25),
//                                         blurRadius: 2.0,
//                                         offset: const Offset(0, 2),
//                                       ),
//                                     ],
//                                   ),
//                                   child: IconButton(
//                                     onPressed: () async {
//                                       final controller = await mapControllerCompleter.future;
//                                       await controller.setLocationTrackingMode(
//                                           NLocationTrackingMode.follow);
//                                     },
//                                     iconSize: 24.h,
//                                     icon: const Icon(
//                                       AppIcons.currentLocation,
//                                       color: AppColors.currentLocationButtonIcon,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             )
//                           ],
//                         ),
//                       ),
//
//                       // 위치 정보 및 버튼 영역
//                       Expanded(
//                         flex: 370,
//                         child: Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 32.0.w),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               SizedBox(height: 32.0.h),
//                               Text(
//                                 '현재 위치가 $currentAdress 이내에 있어요',
//                                 style: CustomTextStyles.p2,
//                               ),
//                               SizedBox(height: 20.0.h),
//                               Container(
//                                 padding: EdgeInsets.symmetric(
//                                     horizontal: 20.0.w, vertical: 12.0.h),
//                                 decoration: BoxDecoration(
//                                   color: AppColors.locationVerificationAreaLabel,
//                                   borderRadius: BorderRadius.circular(100.0.r),
//                                 ),
//                                 child: Text(
//                                   "$siDo $siGunGu $eupMyoenDong",
//                                   style: CustomTextStyles.p2,
//                                 ),
//                               ),
//                               SizedBox(height: 113.0.h),
//                               SizedBox(
//                                 width: 316.w,
//                                 child: TextButton(
//                                   style: TextButton.styleFrom(
//                                     backgroundColor: AppColors.primaryYellow,
//                                     foregroundColor: AppColors.textColorBlack,
//                                     padding: EdgeInsets.symmetric(vertical: 20.0.h),
//                                     minimumSize: Size(316.w, 0),
//                                   ),
//                                   onPressed: () => _onVerifyLocationPressed(),
//                                   child: Text(
//                                     '위치 인증하기',
//                                     style: CustomTextStyles.p1.copyWith(
//                                       color: Colors.black,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }
//
//   // 위치 인증 버튼 클릭 시 처리
//   Future<void> _onVerifyLocationPressed() async {
//     if (_currentPosition != null) {
//       try {
//         // 위치 정보가 비어있는지 확인
//         if (siDo.isEmpty || siGunGu.isEmpty || eupMyoenDong.isEmpty) {
//           await getAddressByNaverApi(_currentPosition!);
//
//           if (siDo.isEmpty || siGunGu.isEmpty || eupMyoenDong.isEmpty) {
//             if (context.mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('위치 정보를 가져오지 못했습니다. 다시 시도해주세요.')),
//               );
//             }
//             return;
//           }
//         }
//
//         await MemberApi().saveMemberLocation(
//           longitude: _currentPosition!.longitude,
//           latitude: _currentPosition!.latitude,
//           siDo: siDo,
//           siGunGu: siGunGu,
//           eupMyoenDong: eupMyoenDong,
//           ri: ri,
//         );
//         var userInfo = UserInfo();
//         await UserInfo().getUserInfo();
//
//         if (context.mounted) {
//           context.navigateTo(
//               screen: userInfo.isFirstLogin! && !userInfo.isItemCategorySaved!
//                   ? const CategorySelectionScreen()
//                   : const MainScreen(),
//               type: NavigationTypes.push);
//         }
//       } catch (e) {
//         log("위치 정보 저장 실패: $e");
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('위치 저장에 실패했습니다: $e')),
//           );
//         }
//       }
//     }
//   }
//
//   // 위치 권한 요청
//   Future<void> _permission() async {
//     var requestStatus = await Permission.location.request();
//     var status = await Permission.location.status;
//
//     // 권한 거부된 경우 > 앱설정 화면
//     if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
//       openAppSettings();
//     } else {
//       // 권한 부여된 경우 > 현재 위치 가져오기
//       await _getCurrentPosition();
//     }
//   }
//
//   // 현재 위치 가져오기
//   Future<void> _getCurrentPosition() async {
//     try {
//       final position = await Geolocator.getCurrentPosition();
//       setState(() {
//         _currentPosition = NLatLng(position.latitude, position.longitude);
//       });
//     } catch (e) {
//       log('Error getting location: $e');
//     }
//   }
//
//   // 네이버 API를 사용 : 주소 정보 가져오기
//   Future<void> getAddressByNaverApi(NLatLng position) async {
//     const String naverReverseGeoCodeApiUrl = AppUrls.naverReverseGeoCodeApiUrl;
//     String coords = "${position.longitude},${position.latitude}";
//     const String orders = "legalcode";
//     const String output = "json";
//
//     try {
//       final requestUrl = "$naverReverseGeoCodeApiUrl?coords=$coords&orders=$orders&output=$output";
//
//       final response = await http.get(
//         Uri.parse(requestUrl),
//         headers: {
//           "X-NCP-APIGW-API-KEY-ID": dotenv.get('NMF_CLIENT_ID'),
//           "X-NCP-APIGW-API-KEY": dotenv.get('NMF_CLIENT_SECRET'),
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final NaverAddressResponse addressData = NaverAddressResponse.fromJson(json.decode(response.body));
//
//         if (addressData.results.isNotEmpty) {
//           final region = addressData.results[0].region;
//
//           setState(() {
//             siDo = region.area1.name;
//             siGunGu = region.area2.name;
//             eupMyoenDong = region.area3.name;
//             ri = region.area4.name.isNotEmpty ? region.area4.name : null;
//             currentAdress = eupMyoenDong;
//           });
//         }
//       }
//     } catch (e) {
//       log("주소 요청 중 오류 발생: $e");
//     }
//   }
// }