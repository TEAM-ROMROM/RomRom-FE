import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 물품 카드 비율 계산 유틸리티 클래스
class ItemCardScale {
  final double scale;

  const ItemCardScale(this.scale);

  // 주어진 값에 scale 비율을 곱해서 반환
  double s(double value) => value * scale;

  // 주어진 fontSize에 scale 비율 적용
  double fontSize(double value) => value * scale;

  // 수평/수직 padding을 scale 비율로 계산
  EdgeInsets padding(double h, double v) => EdgeInsets.symmetric(horizontal: s(h), vertical: s(v));

  // margin을 scale 비율로 계산
  EdgeInsets margin({double l = 0, double t = 0, double r = 0, double b = 0}) =>
      EdgeInsets.fromLTRB(s(l), s(t), s(r), s(b));

  // border radius를 scale 비율로 계산
  BorderRadius radius(double r) => BorderRadius.circular(s(r));

  // 높이만 있는 SizedBox 생성 (scale 적용)
  SizedBox sizedBoxH(double h) => SizedBox(height: s(h));
}

/// ChangeNotifier 기반의 scale 관리
class ItemCardScaleProvider with ChangeNotifier {
  ItemCardScale _scale = const ItemCardScale(1.0);

  // baseWidth 기준으로 현재 scale 계산 및 갱신
  void setScale(double baseWidth, double currentWidth) {
    _scale = ItemCardScale(currentWidth / baseWidth);
    notifyListeners();
  }

  ItemCardScale get scale => _scale;
}

/// 카드의 상태를 나타내는 State 클래스
class ItemCardState {
  final ItemCardScale scale; // 크기 비율 정보
  final List<String> selectedOptions; // 선택된 옵션 목록

  ItemCardState({required this.scale, this.selectedOptions = const []});

  // state 복사 후 일부 속성만 업데이트
  ItemCardState copyWith({ItemCardScale? scale, List<String>? selectedOptions}) {
    return ItemCardState(scale: scale ?? this.scale, selectedOptions: selectedOptions ?? this.selectedOptions);
  }
}

/// StateNotifier: 카드 상태 변경 로직을 관리
/// : AsyncValue를 사용하여 비동기 상태 관리
class ItemCardNotifier extends StateNotifier<AsyncValue<ItemCardState>> {
  ItemCardNotifier() : super(const AsyncValue.loading()) {
    // 초기 상태 설정
    _initialize();
  }

  void _initialize() {
    state = AsyncValue.data(ItemCardState(scale: const ItemCardScale(1.0)));
  }

  // baseWidth 대비 currentWidth로 scale 계산 후 상태 업데이트
  void setScale(double baseWidth, double currentWidth) {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(scale: ItemCardScale(currentWidth / baseWidth)));
    });
  }

  // 옵션 선택/해제 toggle 로직
  void toggleOption(String option) {
    state.whenData((currentState) {
      final currentOptions = List<String>.from(currentState.selectedOptions);
      if (currentOptions.contains(option)) {
        currentOptions.remove(option);
      } else {
        currentOptions.add(option);
      }
      state = AsyncValue.data(currentState.copyWith(selectedOptions: currentOptions));
    });
  }

  // 선택된 옵션 초기화
  void clearOptions() {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(selectedOptions: const []));
    });
  }
}

/// 카드별 Provider: cardId별로 독립적인 상태 관리 가능
final itemCardProvider = StateNotifierProvider.family<ItemCardNotifier, AsyncValue<ItemCardState>, String>(
  (ref, itemId) => ItemCardNotifier(),
);
