import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/responses/chat_response.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/providers/chat_repository_provider.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/repositories/chat_repository.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/screens/chat_tab_screen.dart';
import 'package:romrom_fe/screens/register_tab_screen.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import '../helpers/pump_design_screen.dart';

/// 내 물품 조회: 실패 모드면 throw, 아니면 [pendingResponse] 완료까지 대기 (재시도 진행 중 재현)
class _FailingItemRepository implements ItemRepository {
  bool isFailing = true;
  int getMyItemsCallCount = 0;
  Completer<List<Item>> pendingResponse = Completer<List<Item>>();

  @override
  Future<List<Item>> getMyItems(ItemStatus status, {int pageSize = 100}) async {
    getMyItemsCallCount++;
    if (isFailing) throw Exception('boom');
    return pendingResponse.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 채팅방 조회 항상 실패
class _FailingChatRepository implements ChatRepository {
  int getChatRoomsCallCount = 0;

  @override
  Future<PagedChatRoomDetail> getChatRooms({required int pageNumber, int pageSize = 10}) async {
    getChatRoomsCallCount++;
    throw Exception('boom');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 화면 렌더 (ScreenUtil + ProviderScope override)
Future<void> pumpScreen(WidgetTester tester, {required Widget screen, required List<Override> overrides}) async {
  useDesignScreenView(tester);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: buildDesignScreenApp(home: screen),
    ),
  );
  // 첫 로드 실패 반영 (무한 애니메이션 위젯이 있어 pumpAndSettle 대신 고정 pump)
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('등록 탭: myItemsProvider 첫 로드 실패', () {
    testWidgets('에러 뷰 + 다시 시도 표시 (빈 상태 문구 아님)', (tester) async {
      final itemRepository = _FailingItemRepository();
      await pumpScreen(
        tester,
        screen: const RegisterTabScreen(),
        overrides: [itemRepositoryProvider.overrideWithValue(itemRepository)],
      );

      expect(find.text('물품을 불러오지 못했어요'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.text('등록된 물품이 없어요.'), findsNothing);
    });

    testWidgets('다시 시도 진행 중 스피너 + 중복 탭 무시 > 성공 시 목록 표시', (tester) async {
      final itemRepository = _FailingItemRepository();
      await pumpScreen(
        tester,
        screen: const RegisterTabScreen(),
        overrides: [itemRepositoryProvider.overrideWithValue(itemRepository)],
      );
      final callCountAfterInitialLoad = itemRepository.getMyItemsCallCount;

      // 재시도: 응답 대기 상태로 전환
      itemRepository.isFailing = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      expect(find.text('다시 시도'), findsNothing);
      expect(find.byType(CommonLoadingIndicator), findsWidgets);

      // 진행 중 재탭 > 무시 (조회 1회분 = available·exchanged 2건만 증가)
      await tester.tap(find.byType(CommonLoadingIndicator).first, warnIfMissed: false);
      await tester.pump();
      expect(itemRepository.getMyItemsCallCount - callCountAfterInitialLoad, 2);

      // 응답 완료 > 에러 뷰 사라지고 빈 상태
      itemRepository.pendingResponse.complete(const <Item>[]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('물품을 불러오지 못했어요'), findsNothing);
      expect(find.text('등록된 물품이 없어요.'), findsOneWidget);
    });
  });

  group('채팅 탭: chatRoomsProvider 첫 로드 실패', () {
    testWidgets('에러 뷰 + 다시 시도 표시, 탭 시 재조회', (tester) async {
      final chatRepository = _FailingChatRepository();
      await pumpScreen(
        tester,
        screen: const ChatTabScreen(),
        overrides: [chatRepositoryProvider.overrideWithValue(chatRepository)],
      );

      expect(find.text('채팅을 불러오지 못했어요'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.text('아직 채팅이 없어요'), findsNothing);

      final callCountAfterInitialLoad = chatRepository.getChatRoomsCallCount;
      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 재조회 1회 + 다시 실패 > 에러 뷰 유지 (예외 없이)
      expect(chatRepository.getChatRoomsCallCount - callCountAfterInitialLoad, 1);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
