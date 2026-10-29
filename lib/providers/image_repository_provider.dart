import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/image_repository.dart';
import 'package:romrom_fe/services/apis/image_api.dart';

/// ImageRepository 주입용 공유 Provider (물품 등록·수정, 프로필 이미지 공통, 테스트 override 가능)
final imageRepositoryProvider = Provider<ImageRepository>((ref) => ImageRepository(ImageApi()));
