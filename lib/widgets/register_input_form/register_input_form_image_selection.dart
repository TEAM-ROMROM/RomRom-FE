// 물품 등록 사진 선택: 촬영·앨범 추가(백그라운드 압축 시작), 로컬 삭제, 전체 화면 보기
part of '../register_input_form.dart';

mixin _RegisterInputFormImageSelection on _RegisterInputFormStateFields {
  // 등록 가능한 최대 사진 수
  static const int kMaxImages = 10;

  // 상품사진 추가: 소스(촬영/앨범) 선택 후 처리
  Future<void> onPickImage() async {
    if (_isPickingSource) return; // 중복 진입 방지

    setState(() {
      _hasImageBeenTouched = true;
    });

    final int totalCount = _totalImageCount;
    if (totalCount >= kMaxImages) {
      if (context.mounted) {
        CommonSnackBar.show(context: context, message: '이미지는 최대 10장까지 등록할 수 있습니다.', type: SnackBarType.info);
      }
      return;
    }

    final ImagePickSource? source = await showImageSourceBottomSheet(context);
    if (source == null) return; // 바텀시트 취소

    _isPickingSource = true;
    try {
      switch (source) {
        case ImagePickSource.camera:
          if (!context.mounted) return;
          final bool granted = await ensureCameraPermission(context);
          if (!granted) return;

          final XFile? shot = await _picker.pickImage(source: ImageSource.camera);
          if (shot == null) return; // 촬영 취소

          if (!mounted) return;
          setState(() {
            _newImageFiles.add(shot);
            _compressing.add(ImageCompressor.toWebp(shot));
          });

        case ImagePickSource.gallery:
          final int remain = (kMaxImages - _totalImageCount).clamp(0, kMaxImages);
          final List<XFile> picked = await _picker.pickMultiImage(limit: remain);
          if (picked.isEmpty) return; // 선택 없음/취소

          final List<XFile> toAdd = picked.length > remain ? picked.sublist(0, remain) : picked;
          if (!mounted) return;
          setState(() {
            _newImageFiles.addAll(toAdd);
            _compressing.addAll(toAdd.map(ImageCompressor.toWebp));
          });
      }
    } catch (e) {
      if (context.mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    } finally {
      if (mounted) _isPickingSource = false;
    }
  }

  /// 이미지 삭제 (로컬에서만 제거, 서버 호출 없음)
  void onDeleteImage(int index) {
    if (index < 0 || index >= _totalImageCount) return;

    final int existingCount = _existingImageUrls.length;

    setState(() {
      _hasImageBeenTouched = true;

      if (index < existingCount) {
        // 기존 서버 이미지 삭제
        _existingImageUrls.removeAt(index);
      } else {
        // 새로 추가된 로컬 이미지 삭제 (압축 리스트도 같은 index 제거 → 결과 버림)
        final localIndex = index - existingCount;
        _newImageFiles.removeAt(localIndex);
        _compressing.removeAt(localIndex);
      }
    });
  }

  /// 썸네일 탭 > 전체 화면 보기 (기존 서버 사진 + 새 로컬 사진)
  void _openImageFullscreenViewer(int index) {
    context.navigateTo(
      type: NavigationTypes.fadePush,
      screen: ImageFullscreenViewer(
        existingImageUrls: List.unmodifiable(_existingImageUrls),
        newImageFilePaths: _newImageFiles.map((f) => f.path).toList(growable: false),
        initialIndex: index,
      ),
    );
  }
}
