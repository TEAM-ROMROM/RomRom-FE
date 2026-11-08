// 약속 잡기 시트: 날짜·시간 선택 > 장소 이름 입력 (지도에서 위치 선택 시 좌표 첨부) > 제안 내용 반환 (#1006)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/chat_appointment_proposal.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/utils/chat_message_action_rules.dart';
import 'package:romrom_fe/utils/date_time_display_utils.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

// 시간 선택 간격 (분)
const int _appointmentMinuteInterval = 10;
// 날짜·시간 휠 높이 (고정 px, iPad에서 시트가 화면을 넘지 않게)
const double _dateTimePickerHeight = 180;

/// 약속 잡기 시트 (닫기 > null), [onPickLocation]: 지도 위치 선택 화면 (권한은 그 화면 진입 때 요청)
Future<ChatAppointmentProposal?> showChatAppointmentProposalSheet({
  required BuildContext context,
  required Future<LocationAddress?> Function() onPickLocation,
}) {
  return showModalBottomSheet<ChatAppointmentProposal>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (sheetContext) => _ChatAppointmentProposalSheet(onPickLocation: onPickLocation),
  );
}

/// 처음 보이는 약속 시각: 지금 + 1시간을 선택 간격에 맞춰 올림
DateTime _initialAppointmentAt(DateTime now) {
  final nextHour = now.add(const Duration(hours: 1));
  final roundedMinute = (nextHour.minute / _appointmentMinuteInterval).ceil() * _appointmentMinuteInterval;
  return DateTime(nextHour.year, nextHour.month, nextHour.day, nextHour.hour).add(Duration(minutes: roundedMinute));
}

class _ChatAppointmentProposalSheet extends StatefulWidget {
  final Future<LocationAddress?> Function() onPickLocation;

  const _ChatAppointmentProposalSheet({required this.onPickLocation});

  @override
  State<_ChatAppointmentProposalSheet> createState() => _ChatAppointmentProposalSheetState();
}

class _ChatAppointmentProposalSheetState extends State<_ChatAppointmentProposalSheet> {
  final TextEditingController _placeNameController = TextEditingController();
  late DateTime _appointmentAt = _initialAppointmentAt(DateTime.now());
  // 지도에서 고른 좌표 (선택 안 하면 null > 장소 이름만 전송)
  LocationAddress? _pickedLocation;
  // 위치 선택 화면 중복 진입 방지
  bool _isPickingLocation = false;

  @override
  void initState() {
    super.initState();
    _placeNameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => isAppointmentProposalValid(
    appointmentAt: _appointmentAt,
    placeName: _placeNameController.text,
    now: DateTime.now(),
  );

  /// 지도 위치 선택 > 좌표 보관, 장소 이름이 비어 있으면 동 이름으로 채움
  Future<void> _onPickLocationPressed() async {
    if (_isPickingLocation) return;
    _isPickingLocation = true;
    try {
      final pickedLocation = await widget.onPickLocation();
      if (!mounted || pickedLocation == null || pickedLocation.latitude == null) return;
      setState(() => _pickedLocation = pickedLocation);
      if (_placeNameController.text.trim().isEmpty) _placeNameController.text = pickedLocation.eupMyoenDong;
    } finally {
      _isPickingLocation = false;
    }
  }

  void _onSubmitPressed() {
    if (!_canSubmit) return;
    Navigator.of(context).pop(
      ChatAppointmentProposal(
        appointmentAt: _appointmentAt,
        placeName: _placeNameController.text.trim(),
        latitude: _pickedLocation?.latitude,
        longitude: _pickedLocation?.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryBlack,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(24.w, 20, 24.w, 16 + MediaQuery.of(context).padding.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('약속 잡기', style: CustomTextStyles.h3.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                formatAppointmentDateTime(_appointmentAt),
                style: CustomTextStyles.p2.copyWith(color: AppColors.primaryYellow),
              ),
              SizedBox(height: _dateTimePickerHeight, child: _buildDateTimePicker()),
              const SizedBox(height: 16),
              _buildPlaceNameField(),
              const SizedBox(height: 12),
              _buildPickLocationRow(),
              const SizedBox(height: 20),
              CompletionButton(isEnabled: _canSubmit, buttonText: '약속 보내기', enabledOnPressed: _onSubmitPressed),
            ],
          ),
        ),
      ),
    );
  }

  /// 날짜·시간 휠 (어두운 테마, 오늘부터 선택, 10분 간격)
  Widget _buildDateTimePicker() {
    final now = DateTime.now();
    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: Brightness.dark,
        textTheme: CupertinoTextThemeData(
          dateTimePickerTextStyle: CustomTextStyles.p1.copyWith(color: AppColors.textColorWhite),
        ),
      ),
      child: CupertinoDatePicker(
        initialDateTime: _appointmentAt,
        minimumDate: DateTime(now.year, now.month, now.day),
        minuteInterval: _appointmentMinuteInterval,
        use24hFormat: false,
        onDateTimeChanged: (selectedDateTime) => setState(() => _appointmentAt = selectedDateTime),
      ),
    );
  }

  Widget _buildPlaceNameField() {
    return TextField(
      controller: _placeNameController,
      maxLength: appointmentPlaceNameMaximumLength,
      style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite),
      cursorColor: AppColors.primaryYellow,
      decoration: InputDecoration(
        hintText: '만날 장소 (예: 군자역 2번 출구)',
        hintStyle: CustomTextStyles.p2.copyWith(color: AppColors.opacity50White),
        filled: true,
        fillColor: AppColors.opacity10White,
        counterStyle: CustomTextStyles.p3.copyWith(color: AppColors.opacity50White),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  /// 지도에서 위치 선택 (선택됨 > 동 이름 표시)
  Widget _buildPickLocationRow() {
    final pickedLocation = _pickedLocation;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onPickLocationPressed,
      child: Row(
        children: [
          const Icon(AppIcons.location, size: 18, color: AppColors.opacity60White),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pickedLocation == null ? '지도에서 위치 선택 (선택)' : '위치 첨부됨 · ${pickedLocation.currentAddress}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White),
            ),
          ),
        ],
      ),
    );
  }
}
