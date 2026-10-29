// 채팅방 첨부 전송: 사진(선택 > 업로드 중 버블 > 압축·업로드 > 전송), 위치
part of '../chat_room_screen.dart';

mixin _ChatRoomAttachmentSending on _ChatRoomScreenStateFields, _ChatRoomMessaging {
  /// 사진 전송: 선택 > 업로드 중 버블 표시 > webp 압축·업로드 > 이미지 메시지 전송 (실패 시 버블 제거·안내)
  Future<void> _onPickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    FocusScope.of(context).unfocus();
    try {
      final List<XFile> picked = await _picker.pickMultiImage(limit: 10);
      if (!mounted) return;
      if (picked.isEmpty) return;

      final localId = 'uploading_${DateTime.now().microsecondsSinceEpoch}';
      _latestLocalTradeRequestId = localId;
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            chatRoomId: widget.chatRoomId,
            chatMessageId: localId,
            senderId: _myMemberId,
            createdDate: DateTime.now(),
            content: '사진을 보냈습니다.',
            type: MessageType.image,
            imageUrls: picked.map((f) => f.path).toList(),
          ),
        );
        _uploadingLocalIds.add(localId);
      });
      _scrollToBottom();

      try {
        final imageRepository = ref.read(imageRepositoryProvider);
        final compressed = await Future.wait(picked.map(ImageCompressor.toWebp));
        final uploadedImageUrls = await imageRepository.uploadImages(compressed);
        if (!mounted) return;

        setState(() {
          _messages.removeWhere((m) => m.chatMessageId == localId);
          _uploadingLocalIds.remove(localId);
        });

        if (uploadedImageUrls.isEmpty) {
          CommonSnackBar.show(context: context, message: '이미지 업로드 실패', type: SnackBarType.error);
          return;
        }

        final textMessage = _messageController.text.trim();
        if (!mounted) return;
        await _sendImage(imageUrls: uploadedImageUrls, imageMessage: textMessage.isNotEmpty ? textMessage : null);
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => m.chatMessageId == localId);
            _uploadingLocalIds.remove(localId);
          });
          _showErrorSnackBar(e);
        }
      }
    } catch (e) {
      if (context.mounted) _showErrorSnackBar(e);
    } finally {
      if (mounted) _isPickingImage = false;
    }
  }

  /// 위치 메시지 전송 플로우: 위치 선택 → 메시지 전송
  Future<void> _onSendLocation() async {
    if (_isInputDisabled) return;
    FocusScope.of(context).unfocus();

    final LocationAddress? result = await context.navigateTo<LocationAddress>(screen: const ChatLocationPickerScreen());

    if (result == null || !mounted) return;

    final lat = result.latitude;
    final lng = result.longitude;
    if (lat == null || lng == null) return;

    _wsService.sendMessage(
      chatRoomId: widget.chatRoomId,
      content: '위치를 보냈습니다.',
      type: MessageType.location,
      latitude: lat,
      longitude: lng,
    );
  }
}
