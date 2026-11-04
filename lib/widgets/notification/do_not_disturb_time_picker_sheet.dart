import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

/// 방해금지 시각 선택 시트: 24시간 휠(10분 단위) > 확인 시 선택 시각 반환, 닫으면 null (#1007)
class DoNotDisturbTimePickerSheet {
  const DoNotDisturbTimePickerSheet._();

  // 휠 분 단위 (서버는 분 단위 저장, 선택 편의상 10분)
  static const int minuteIntervalMinutes = 10;

  static Future<TimeOfDay?> show({
    required BuildContext context,
    required String title,
    required TimeOfDay initialTime,
  }) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DoNotDisturbTimePicker(title: title, initialTime: initialTime),
    );
  }

  /// 휠 단위에 맞게 분 내림 (CupertinoDatePicker는 단위 배수 분만 허용)
  static TimeOfDay alignToMinuteInterval(TimeOfDay time) =>
      TimeOfDay(hour: time.hour, minute: time.minute - time.minute % minuteIntervalMinutes);
}

class _DoNotDisturbTimePicker extends StatefulWidget {
  final String title;
  final TimeOfDay initialTime;

  const _DoNotDisturbTimePicker({required this.title, required this.initialTime});

  @override
  State<_DoNotDisturbTimePicker> createState() => _DoNotDisturbTimePickerState();
}

class _DoNotDisturbTimePickerState extends State<_DoNotDisturbTimePicker> {
  // 휠 높이 (고정 px, iPad 확대 방지)
  static const double _pickerHeightPixels = 200;

  late TimeOfDay _selectedTime = DoNotDisturbTimePickerSheet.alignToMinuteInterval(widget.initialTime);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // 날짜는 무의미 > 시각만 쓰는 기준일
    final initialDateTime = DateTime(2000, 1, 1, _selectedTime.hour, _selectedTime.minute);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // 드래그 핸들
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.opacity30White, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.title,
              style: CustomTextStyles.p1.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: _pickerHeightPixels,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: Brightness.dark,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: CustomTextStyles.h3.copyWith(color: AppColors.textColorWhite),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                minuteInterval: DoNotDisturbTimePickerSheet.minuteIntervalMinutes,
                initialDateTime: initialDateTime,
                onDateTimeChanged: (dateTime) =>
                    _selectedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
            child: CompletionButton(
              isEnabled: true,
              buttonText: '확인',
              enabledOnPressed: () => Navigator.pop(context, _selectedTime),
            ),
          ),
        ],
      ),
    );
  }
}
