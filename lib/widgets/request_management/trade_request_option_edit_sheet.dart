// 보낸 요청 거래 방식 수정 시트 (저장은 tradeRequestsProvider 경유)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/trade_requests_provider.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/trade_request_trade_option_selector.dart';

/// 거래 방식 수정 시트: 요청의 기존 선택값으로 시작 > 1개 이상·변경 시 저장 가능 > 저장 성공 시 안내 후 닫힘
/// 앱이 모르는 기존 서버 값은 화면에 없지만 그대로 함께 전송 (새 거래 방식 유실 방지)
class TradeRequestOptionEditSheet extends ConsumerStatefulWidget {
  final String tradeRequestHistoryId;

  // 요청의 기존 거래 방식 서버 값 (모르는 값 포함 원본)
  final List<String> originalTradeOptionServerNames;

  const TradeRequestOptionEditSheet({
    super.key,
    required this.tradeRequestHistoryId,
    required this.originalTradeOptionServerNames,
  });

  /// 보낸 요청 1건 수정 시트 열기 (요청 ID 없음 > 무시)
  static Future<void> show({required BuildContext context, required TradeRequestHistory request}) async {
    final tradeRequestHistoryId = request.tradeRequestHistoryId;
    if (tradeRequestHistoryId == null) return;
    // 드래그 닫기 끔 (저장 중 닫힘 방지, 바깥 탭·뒤로가기는 시트의 PopScope가 저장 중 차단)
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      enableDrag: false,
      builder: (_) => TradeRequestOptionEditSheet(
        tradeRequestHistoryId: tradeRequestHistoryId,
        originalTradeOptionServerNames: request.itemTradeOptions,
      ),
    );
  }

  @override
  ConsumerState<TradeRequestOptionEditSheet> createState() => _TradeRequestOptionEditSheetState();
}

class _TradeRequestOptionEditSheetState extends ConsumerState<TradeRequestOptionEditSheet> {
  late final Set<ItemTradeOption> _initialOptions = ItemTradeOption.fromServerNamesSkippingUnknown(
    widget.originalTradeOptionServerNames,
  ).toSet();
  late Set<ItemTradeOption> _selectedOptions = {..._initialOptions};

  // 앱이 모르는 기존 서버 값 (보존 전송)
  late final List<String> _unknownTradeOptionServerNames = [
    for (final serverName in widget.originalTradeOptionServerNames)
      if (ItemTradeOption.fromServerName(serverName) == null) serverName,
  ];

  // 저장 진행 중 여부 (중복 저장 방지)
  bool _isSaving = false;

  bool get _canSave => _selectedOptions.isNotEmpty && !setEquals(_selectedOptions, _initialOptions);

  /// 저장: 진행 중이면 무시 > notifier 수정(선택값 enum 순서 + 모르는 기존 값) > 성공 안내 후 닫기, 실패 안내 (성공·실패 공통 진행 해제)
  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(tradeRequestsProvider.notifier)
          .updateTradeOptions(
            tradeRequestHistoryId: widget.tradeRequestHistoryId,
            itemTradeOptions: [
              for (final option in ItemTradeOption.values)
                if (_selectedOptions.contains(option)) option.serverName,
              ..._unknownTradeOptionServerNames,
            ],
          );
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: '거래 방식을 수정했습니다.', type: SnackBarType.success);
      Navigator.of(context).pop();
    } catch (error) {
      debugPrint('[request management] update trade options failed : $error');
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(error), type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // 모달 고정 px (iPad 확대 방지), 저장 중 바깥 탭·뒤로가기 닫힘 차단
    return PopScope(
      canPop: !_isSaving,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.primaryBlack,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.opacity30White, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '거래 방식 수정',
              style: CustomTextStyles.p1.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TradeRequestTradeOptionSelector(
              selectedOptions: _selectedOptions,
              onChanged: (nextOptions) => setState(() => _selectedOptions = nextOptions),
            ),
            const SizedBox(height: 16),
            CompletionButton(isEnabled: _canSave, isLoading: _isSaving, buttonText: '수정하기', enabledOnPressed: _save),
          ],
        ),
      ),
    );
  }
}
