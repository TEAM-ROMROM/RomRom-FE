// 채팅방 첨부 전송: 사진(앨범·카메라 > 미리보기 > 업로드 중 버블 > 압축·업로드 > 전송), 위치 (전송 실패는 실패 말풍선으로 표시)
part of '../chat_room_screen.dart';

// 한 번에 보낼 수 있는 사진 최대 수 (말풍선 그리드 최대 10장)
const int _chatImageSendMaximumCount = 10;

mixin _ChatRoomAttachmentSending on _ChatRoomScreenStateFields, _ChatRoomMessaging {
  /// 앨범 사진 전송: 여러 장 선택(최대 10장) > 미리보기·빼기 > 업로드·전송
  Future<void> _onPickImage() =>
      _pickPreviewAndSendImages(pickImages: () => _picker.pickMultiImage(limit: _chatImageSendMaximumCount));

  /// 카메라 사진 전송: 카메라 권한(이 버튼 탭 때만 요청, 거부 시 안내만) > 촬영 > 미리보기 > 업로드·전송
  Future<void> _onTakePhoto() => _pickPreviewAndSendImages(
    pickImages: () async {
      final isCameraGranted = await ensureCameraPermission(context);
      if (!isCameraGranted) return const <XFile>[];
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      return photo == null ? const <XFile>[] : [photo];
    },
  );

  /// 사진 고르기 > 미리보기 시트 (닫기·모두 빼기 > 전송 안 함) > 업로드·전송 (중복 실행 방지, 해제는 finally)
  Future<void> _pickPreviewAndSendImages({required Future<List<XFile>> Function() pickImages}) async {
    if (_isPickingImage || _isInputDisabled) return;
    _isPickingImage = true;
    FocusScope.of(context).unfocus();
    try {
      final picked = await pickImages();
      if (!mounted || picked.isEmpty) return;
      final imagesToSend = await showChatImageSendPreviewSheet(context: context, images: picked);
      if (!mounted || imagesToSend == null || imagesToSend.isEmpty) return;
      await _uploadAndSendImages(imagesToSend);
    } catch (e) {
      if (mounted) _showErrorSnackBar(e);
    } finally {
      if (mounted) _isPickingImage = false;
    }
  }

  /// 업로드 중 버블 표시 > webp 압축·업로드 > 이미지 메시지 전송 (업로드 실패 시 버블 제거·안내, 전송 실패는 실패 말풍선)
  Future<void> _uploadAndSendImages(List<XFile> images) async {
    final localId = buildLocalMessageId(prefix: uploadingMessageIdPrefix);
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          chatRoomId: widget.chatRoomId,
          chatMessageId: localId,
          senderId: _myMemberId,
          createdDate: DateTime.now(),
          content: _imageMessageContent,
          type: MessageType.image,
          imageUrls: images.map((image) => image.path).toList(),
        ),
      );
      _uploadingLocalIds.add(localId);
    });
    _scrollToBottom();

    try {
      final imageRepository = ref.read(imageRepositoryProvider);
      final compressed = await Future.wait(images.map(ImageCompressor.toWebp));
      final uploadedImageUrls = await imageRepository.uploadImages(compressed);
      if (!mounted) return;
      _removeUploadingBubble(localId);
      if (uploadedImageUrls.isEmpty) {
        CommonSnackBar.show(context: context, message: '이미지 업로드 실패', type: SnackBarType.error);
        return;
      }
      _sendImage(imageUrls: uploadedImageUrls);
    } catch (e) {
      if (!mounted) return;
      _removeUploadingBubble(localId);
      _showErrorSnackBar(e);
    }
  }

  void _removeUploadingBubble(String localId) {
    setState(() {
      _messages.removeWhere((message) => message.chatMessageId == localId);
      _uploadingLocalIds.remove(localId);
    });
  }

  /// 위치 메시지 전송: 위치 선택 > 좌표 확인(없으면 안내) > 전송 중 말풍선 (실패 시 실패 말풍선)
  Future<void> _onSendLocation() async {
    if (_isInputDisabled) return;
    FocusScope.of(context).unfocus();

    final LocationAddress? result = await context.navigateTo<LocationAddress>(screen: const ChatLocationPickerScreen());

    if (result == null || !mounted) return;

    final latitude = result.latitude;
    final longitude = result.longitude;
    if (latitude == null || longitude == null) {
      CommonSnackBar.show(context: context, message: '위치 정보를 확인하지 못했어요. 다시 선택해 주세요.', type: SnackBarType.error);
      return;
    }

    _sendAttachmentMessage(
      _buildLocalMessage(type: MessageType.location, content: '위치를 보냈습니다.', latitude: latitude, longitude: longitude),
    );
  }
}
