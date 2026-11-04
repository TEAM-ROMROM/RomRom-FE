import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/services/chat_image_gallery_saver.dart';

/// ChatImageGallerySaver 주입 (사진 전체 보기 저장 버튼, 테스트 override)
final chatImageGallerySaverProvider = Provider<ChatImageGallerySaver>((ref) => ChatImageGallerySaver());
