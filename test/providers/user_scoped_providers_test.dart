import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/member_response.dart';
import 'package:romrom_fe/providers/chat_rooms_provider.dart';
import 'package:romrom_fe/providers/coach_mark_trigger_provider.dart';
import 'package:romrom_fe/providers/current_tab_index_provider.dart';
import 'package:romrom_fe/providers/home_feed_provider.dart';
import 'package:romrom_fe/providers/item_like_provider.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/providers/member_block_provider.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/providers/member_repository_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/providers/notification_list_provider.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/providers/trade_requests_provider.dart';
import 'package:romrom_fe/providers/user_scoped_providers.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/repositories/member_repository.dart';

/// 내 물건 repository 대역: 조회마다 회원별 다른 목록 (계정 전환 재현)
class _FakeItemRepository implements ItemRepository {
  int getMyItemsCallCount = 0;
  String currentMemberId = 'member-a';

  @override
  Future<List<Item>> getMyItems(ItemStatus status, {int pageSize = 100}) async {
    getMyItemsCallCount++;
    return status == ItemStatus.available ? [Item(itemId: '$currentMemberId-item')] : const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 회원 repository 대역: 조회 횟수 기록, 현재 회원 id 반환
class _FakeMemberRepository implements MemberRepository {
  int getMemberInfoCallCount = 0;
  String currentMemberId = 'member-a';

  @override
  Future<MemberResponse> getMemberInfo() async {
    getMemberInfoCallCount++;
    return MemberResponse(member: Member(memberId: currentMemberId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 세션 종료 초기화 검증: 사용자 범위 provider 목록, 초기화 후 재조회·초기값 복귀
void main() {
  late _FakeItemRepository fakeItemRepository;
  late _FakeMemberRepository fakeMemberRepository;
  late ProviderContainer container;

  setUp(() {
    fakeItemRepository = _FakeItemRepository();
    fakeMemberRepository = _FakeMemberRepository();
    container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(fakeItemRepository),
        memberRepositoryProvider.overrideWithValue(fakeMemberRepository),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('목록 > 회원별 상태를 가진 provider 전부 포함', () {
    expect(
      userScopedProviders,
      containsAll(<ProviderOrFamily>[
        myItemsProvider,
        memberProfileProvider,
        chatRoomsProvider,
        notificationListProvider,
        notificationSettingProvider,
        itemLikeProvider,
        memberBlockProvider,
        tradeRequestsProvider,
        homeFeedProvider,
        currentTabIndexProvider,
        coachMarkTriggerProvider,
      ]),
    );
  });

  test('초기화 > 비동기 provider 다음 조회 시 재조회, 새 계정 데이터 반환', () async {
    final previousItems = await container.read(myItemsProvider.future);
    final previousProfile = await container.read(memberProfileProvider.future);
    expect(previousItems.available.single.itemId, 'member-a-item');
    expect(previousProfile.member?.memberId, 'member-a');

    fakeItemRepository.currentMemberId = 'member-b';
    fakeMemberRepository.currentMemberId = 'member-b';
    invalidateUserScopedProviders(container.invalidate);

    final nextItems = await container.read(myItemsProvider.future);
    final nextProfile = await container.read(memberProfileProvider.future);
    expect(fakeItemRepository.getMyItemsCallCount, 4); // available·exchanged 2회 x 2
    expect(fakeMemberRepository.getMemberInfoCallCount, 2);
    expect(nextItems.available.single.itemId, 'member-b-item');
    expect(nextProfile.member?.memberId, 'member-b');
  });

  test('초기화 > 동기 provider 초기값 복귀 (좋아요·차단·탭·코치마크)', () {
    container.read(itemLikeProvider.notifier).seed(itemId: 'item-1', isLiked: true, likeCount: 3);
    container.read(memberBlockProvider.notifier).seed({'blocked-member'});
    container.read(currentTabIndexProvider.notifier).set(4);
    container.read(coachMarkTriggerProvider.notifier).trigger();

    invalidateUserScopedProviders(container.invalidate);

    expect(container.read(itemLikeProvider), isEmpty);
    expect(container.read(memberBlockProvider).blockedIds, isEmpty);
    expect(container.read(currentTabIndexProvider), 0);
    expect(container.read(coachMarkTriggerProvider), isFalse);
  });
}
