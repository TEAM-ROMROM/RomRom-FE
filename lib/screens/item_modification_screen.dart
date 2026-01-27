import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/register_input_form.dart';

/// 물품 수정 화면
class ItemModificationScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final String? itemId;

  const ItemModificationScreen({
    super.key,
    required this.itemId,
    this.onClose,
  });

  @override
  State<ItemModificationScreen> createState() => _ItemModificationScreenState();
}

class _ItemModificationScreenState extends State<ItemModificationScreen> {
  bool _isLoading = true;
  Item? _myItem;

  /// 내 물품 리스트 로드
  Future<void> _loadMyItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final itemApi = ItemApi();
      final request = ItemRequest(itemId: widget.itemId);
      final response = await itemApi.getItemDetail(request);

      setState(() {
        _myItem = response.item!;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CommonSnackBar.show(
          context: context,
          message: '내 물품 상세 정보 로드 실패: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  void initState() {
    _loadMyItems();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: CommonAppBar(
          title: '수정하기',
          onBackPressed: () {
            if (widget.onClose != null) {
              widget.onClose!();
            }
          },
          showBottomBorder: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                color: AppColors.primaryYellow,
              ))
            : SingleChildScrollView(
                padding: EdgeInsets.only(top: 24.h, bottom: 24.h, left: 24.w),
                child: RegisterInputForm(
                  isEditMode: true, // true면 수정화면
                  item: _myItem, // 수정 모드에서 사용
                )),
      ),
    );
  }
}
