import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/register_input_form.dart';

/// 물품 수정 화면
class ItemModificationScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const ItemModificationScreen({super.key, this.onClose});

  @override
  State<ItemModificationScreen> createState() => _ItemModificationScreenState();
}

class _ItemModificationScreenState extends State<ItemModificationScreen> {
  bool _isLoading = true;
  ItemResponse _myItem = ItemResponse();

  /// 내 물품 리스트 로드
  Future<void> _loadMyItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final itemApi = ItemApi();
      final request = ItemRequest(
          itemId:
              "024a639b-c9be-4e49-b492-77259736177f"); // FIXME : 실제 아이템 ID로 변경 필요
      final response = await itemApi.getItemDetail(request);

      setState(() {
        _myItem = response;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('내 물품 상세 정보 로드 실패: $e')));
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
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: EdgeInsets.only(top: 24.h, bottom: 24.h, left: 24.w),
                child: RegisterInputForm(
                  isEditMode: true, // true면 수정화면
                  itemResponse: _myItem, // 수정 모드에서 사용
                )),
      ),
    );
  }
}
