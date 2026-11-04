// reverse 목록(offset 0 = 맨 아래) 특정 항목까지 이동: 렌더 안 된 먼 항목은 위로 한 화면씩 넘기며 찾기
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 키 항목까지 이동 > 화면 [alignment] 위치에 맞춤 (1.0 맨 위, 0.0 맨 아래)
/// 반환: 찾아서 이동함 여부 (맨 위 도달·시도 횟수 초과·[isActive] false > false)
Future<bool> scrollReverseListToKeyedItem({
  required ScrollController scrollController,
  required GlobalKey itemKey,
  required double alignment,
  required int maximumAttemptCount,
  required bool Function() isActive,
}) async {
  for (var attempt = 0; attempt < maximumAttemptCount; attempt++) {
    await WidgetsBinding.instance.endOfFrame;
    if (!isActive() || !scrollController.hasClients) return false;
    final itemContext = itemKey.currentContext;
    if (itemContext != null) {
      await Scrollable.ensureVisible(itemContext, alignment: alignment);
      return true;
    }
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent) return false;
    scrollController.jumpTo(math.min(position.pixels + position.viewportDimension, position.maxScrollExtent));
  }
  return false;
}
