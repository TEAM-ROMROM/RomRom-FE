// 물품 상세 조회: 표시 물품 반영(목록 원본 먼저, 상세 응답으로 교체), 상세 조회·실패 처리, 물품·회원 좌표 주소 변환
part of '../item_detail_description_screen.dart';

mixin _ItemDetailLoading on _ItemDetailDescriptionScreenStateFields {
  /// 표시 물품 반영 (setState 안·initState에서 호출): 이미지 목록 > 물품·회원 좌표 주소 변환 시작
  void _applyItem(Item? nextItem) {
    item = nextItem;
    imageUrls = nextItem?.imageUrlList ?? const []; // imageUrl null 제거

    // 물품 좌표를 주소로 변환
    if (nextItem?.latitude != null && nextItem?.longitude != null) {
      _resolveAddressName(
        latitude: nextItem!.latitude!,
        longitude: nextItem.longitude!,
        formatAddress: LocationUtils.formatAddress,
        onResolved: (addressName) => locationName = addressName,
        failureLogLabel: '주소 변환 실패',
      );
    }

    // 회원 좌표를 주소로 변환
    if (nextItem?.member?.latitude != null && nextItem?.member?.longitude != null) {
      _resolveAddressName(
        latitude: nextItem!.member!.latitude!,
        longitude: nextItem.member!.longitude!,
        formatAddress: LocationUtils.formatMediumAddress,
        onResolved: (addressName) => memberLocationName = addressName,
        failureLogLabel: '회원 주소 변환 실패',
      );
    }
  }

  /// 상세 조회: 표시 중인 물품 없을 때만 스켈레톤 > 응답 반영 > 좋아요 캐시 시드 (실패 시 오류 화면)
  Future<void> _loadItemDetail() async {
    try {
      setState(() {
        isLoading = item == null;
        hasError = false;
      });

      final ItemResponse response = await ref.read(itemRepositoryProvider).getItemDetail(widget.itemId);

      if (!mounted) return;

      setState(() {
        _applyItem(response.item);
        isLoading = false;
      });

      // 캐시 시드 (force=true: 서버 최신값 우선)
      final id = item?.itemId;
      if (id != null && id.isNotEmpty) {
        ref
            .read(itemLikeProvider.notifier)
            .seed(itemId: id, isLiked: response.isLiked == true, likeCount: item?.likeCount ?? 0, force: true);
      }
    } catch (e) {
      debugPrint('물품 상세 정보 로드 실패: $e');
      if (!mounted) return;

      if (ErrorUtils.getErrorMessage(e) == ErrorCode.deletedMember.koMessage) {
        CommonModal.showOnceAfterFrame(
          context: context,
          isShown: () => deleteModalShown,
          markShown: () => deleteModalShown = true,
          shouldShow: () => ErrorUtils.getErrorMessage(e) == ErrorCode.deletedMember.koMessage,
          message: '존재하지 않거나 탈퇴한 사용자입니다.',
          onConfirm: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        );
      }

      final errorCode = ErrorUtils.getErrorCode(e);
      // 볼 수 없는 물품 > 홈 피드에서 즉시 제거·이후 조회에서도 제외 (#995)
      if (errorCode.isUnavailableItemError) {
        ref.read(homeFeedProvider.notifier).excludeUnavailableItem(widget.itemId);
      }
      setState(() {
        hasError = true;
        errorMessage = errorCode.koMessage;
        _isDeletedItem = errorCode == ErrorCode.deletedItem || errorCode == ErrorCode.itemNotFound;
        isLoading = false;
      });
    }
  }

  /// 좌표 > 주소 문자열 (실패·없음 시 '위치 정보 없음', 물품: 짧은 주소 / 회원: 중간 주소)
  Future<void> _resolveAddressName({
    required double latitude,
    required double longitude,
    required String Function(LocationAddress address) formatAddress,
    required void Function(String addressName) onResolved,
    required String failureLogLabel,
  }) async {
    try {
      final address = await LocationService().getAddressFromCoordinates(NLatLng(latitude, longitude));
      if (!mounted) return;
      setState(() => onResolved(address != null ? formatAddress(address) : '위치 정보 없음'));
    } catch (e) {
      debugPrint('$failureLogLabel: $e');
      if (mounted) setState(() => onResolved('위치 정보 없음'));
    }
  }
}
