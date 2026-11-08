import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_sort_field.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/providers/home_feed_provider.dart';
import 'package:romrom_fe/providers/home_feed_repository_provider.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/providers/member_block_provider.dart';
import 'package:romrom_fe/providers/notification_repository_provider.dart';
import 'package:romrom_fe/repositories/home_feed_repository.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/repositories/notification_repository.dart';
import 'package:romrom_fe/screens/home_tab_screen.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';
import 'package:romrom_fe/utils/location_verification_gate.dart';
import 'package:romrom_fe/widgets/home_feed_item_widget.dart';
import 'package:romrom_fe/widgets/home_tab/home_tab_register_button.dart';

import '../helpers/pump_design_screen.dart';

/// 좌표 없는 물품 (주소 조회 없이 '미지정')
Item _feedItem(String itemId) => Item(itemId: itemId, itemName: 'name-$itemId', price: 1000);

/// 작성자 지정 물품 (차단 제외 검증)
Item _feedItemBy(String itemId, String authorMemberId) => Item(
  itemId: itemId,
  itemName: 'name-$itemId',
  price: 1000,
  member: Member(memberId: authorMemberId),
);

/// 홈 피드 대역: 첫 페이지만 응답, 다음 페이지는 끝나지 않음 (하단 로딩 칸 유지)
class _FirstPageOnlyFeedRepository implements HomeFeedRepository {
  final List<Item> firstPageItems;

  _FirstPageOnlyFeedRepository(this.firstPageItems);

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
    List<String> recentlySeenItemIds = const [],
    int? feedSeed,
  }) {
    if (pageNumber == 0) return Future.value(firstPageItems);
    return Completer<List<Item>>().future;
  }

  @override
  Future<List<String>> loadRecentlySeenItemIds() async => const [];

  @override
  Future<String?> readCurrentMemberId() async => 'member-1';

  @override
  Future<void> saveRecentlySeenItemIds(List<String> recentlySeenItemIds, {required String memberId}) async {}
}

/// 내 물품 대역: 교환 가능·교환 완료 목록 지정, 상세 조회는 실패 (카드 좋아요 동기화 생략)
class _MyItemsRepository implements ItemRepository {
  final List<Item> availableItems;
  final List<Item> exchangedItems;

  _MyItemsRepository({required this.availableItems, this.exchangedItems = const []});

  @override
  Future<List<Item>> getMyItems(ItemStatus status, {int pageSize = 100}) async =>
      status == ItemStatus.available ? availableItems : exchangedItems;

  @override
  Future<ItemResponse> getItemDetail(String? itemId) async => throw Exception('not needed');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 알림 대역: 모든 호출 실패 (배지 미표시)
class _FailingNotificationRepository implements NotificationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<Never>.error(Exception('not needed'));
}

/// 동네 인증 확인 대역: 요청 목적 기록, 결과 지정 (기본 미인증·취소)
class _RecordingLocationVerificationGate extends LocationVerificationGate {
  final List<LocationVerificationPurpose> requestedPurposes = [];

  _RecordingLocationVerificationGate(super.ref);

  @override
  Future<bool> ensureVerified(BuildContext context, {required LocationVerificationPurpose purpose}) async {
    requestedPurposes.add(purpose);
    return false;
  }
}

Future<ProviderContainer> pumpHomeTab(
  WidgetTester tester, {
  required List<Item> feedItems,
  required ItemRepository itemRepository,
  List<Override> extraOverrides = const [],
}) async {
  useDesignScreenView(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeFeedRepositoryProvider.overrideWithValue(_FirstPageOnlyFeedRepository(feedItems)),
        itemRepositoryProvider.overrideWithValue(itemRepository),
        notificationRepositoryProvider.overrideWithValue(_FailingNotificationRepository()),
        ...extraOverrides,
      ],
      child: buildDesignScreenApp(home: const Scaffold(body: HomeTabScreen())),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return ProviderScope.containerOf(tester.element(find.byType(HomeTabScreen)));
}

/// 홈 피드 세로 PageView 컨트롤러
PageController feedPageController(WidgetTester tester) => tester
    .widgetList<PageView>(find.byType(PageView))
    .firstWhere((pageView) => pageView.scrollDirection == Axis.vertical)
    .controller!;

Future<void> jumpToFeedPage(WidgetTester tester, int pageIndex) async {
  feedPageController(tester).jumpToPage(pageIndex);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('HomeTabScreen 피드 축소 후 현재 페이지 보정', () {
    testWidgets('마지막 물품 신고 제외 > 로딩 칸에 남지 않고 새 마지막 물품으로 이동', (tester) async {
      final container = await pumpHomeTab(
        tester,
        feedItems: [_feedItem('a'), _feedItem('b')],
        itemRepository: _MyItemsRepository(availableItems: [_feedItem('mine')]),
      );
      await jumpToFeedPage(tester, 1);
      expect(find.text('name-b'), findsOneWidget);

      container.read(homeFeedProvider.notifier).excludeReportedItem('b');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(feedPageController(tester).page, 0);
      expect(find.text('name-a'), findsOneWidget);
    });

    testWidgets('차단으로 보던 물품 앞 물품이 빠짐 > 보던 물품 그대로 표시', (tester) async {
      final container = await pumpHomeTab(
        tester,
        feedItems: [
          _feedItemBy('a', 'blocked'),
          _feedItemBy('b', 'other'),
          _feedItemBy('c', 'other'),
          _feedItemBy('d', 'blocked'),
          _feedItemBy('e', 'other'),
        ],
        itemRepository: _MyItemsRepository(availableItems: [_feedItem('mine')]),
      );
      await jumpToFeedPage(tester, 2);
      expect(find.text('name-c'), findsOneWidget);

      container.read(memberBlockProvider.notifier).seed({'blocked'}, force: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(feedPageController(tester).page, 1);
      expect(find.text('name-c'), findsOneWidget);
    });

    testWidgets('보던 광고 칸 로드 실패 > 칸 접히고 그 자리에 다음 물품 표시', (tester) async {
      await pumpHomeTab(
        tester,
        feedItems: [
          for (final itemId in ['a', 'b', 'c', 'd', 'e', 'f']) _feedItem(itemId),
        ],
        itemRepository: _MyItemsRepository(availableItems: [_feedItem('mine')]),
      );

      // 첫 광고 칸: 물품 5개 뒤 (테스트 환경은 광고 ID 없음 > 로드 실패 처리)
      await jumpToFeedPage(tester, 5);

      expect(feedPageController(tester).page, 5);
      expect(find.text('name-f'), findsOneWidget);
    });
  });

  group('HomeTabScreen 블러 문구', () {
    testWidgets('교환 가능 물품 없음 + 교환 완료 물품 있음 > 교환 가능한 물품 없음 문구 전달', (tester) async {
      await pumpHomeTab(
        tester,
        feedItems: [_feedItem('a')],
        itemRepository: _MyItemsRepository(availableItems: const [], exchangedItems: [_feedItem('done')]),
      );

      final feedItemWidget = tester.widget<HomeFeedItemWidget>(find.byType(HomeFeedItemWidget));
      expect(feedItemWidget.showBlur, true);
      expect(feedItemWidget.hasExchangedItems, true);
      expect(find.text('교환 가능한 물품이 없어요\n새 물품을 등록해 주세요!'), findsOneWidget);
    });

    testWidgets('등록 이력 없음 > 첫 등록 안내 문구', (tester) async {
      await pumpHomeTab(
        tester,
        feedItems: [_feedItem('a')],
        itemRepository: _MyItemsRepository(availableItems: const []),
      );

      expect(tester.widget<HomeFeedItemWidget>(find.byType(HomeFeedItemWidget)).hasExchangedItems, false);
      expect(find.text('교환을 시작하려면\n먼저 나의 물품을 등록해 주세요!'), findsOneWidget);
    });
  });

  group('HomeTabScreen 동네 인증', () {
    testWidgets('블러 등록 버튼 > 물품 등록 인증 확인, 미인증·취소 > 등록 화면 미진입 (홈 계속 사용)', (tester) async {
      late _RecordingLocationVerificationGate recordingGate;
      await pumpHomeTab(
        tester,
        feedItems: [_feedItem('a')],
        itemRepository: _MyItemsRepository(availableItems: const []),
        extraOverrides: [
          locationVerificationGateProvider.overrideWith(
            (ref) => recordingGate = _RecordingLocationVerificationGate(ref),
          ),
        ],
      );

      await tester.tap(find.byType(HomeTabRegisterButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(recordingGate.requestedPurposes, [LocationVerificationPurpose.itemRegistration]);
      expect(find.byType(ItemRegisterScreen), findsNothing);
      expect(find.byType(HomeFeedItemWidget), findsOneWidget);
    });
  });
}
