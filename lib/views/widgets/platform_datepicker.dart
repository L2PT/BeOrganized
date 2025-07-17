import 'package:flutter/material.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class PlatformDatePicker {

  static Widget dialog_theme(BuildContext context, Widget? child) {
    return Theme(
      data: ThemeData.light().copyWith(
        dialogTheme: DialogThemeData(
          surfaceTintColor: Colors.transparent,
        ),
        colorScheme: ColorScheme.light().copyWith(
          primary: black,),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: white,
          dialBackgroundColor: grey_light,
          dayPeriodTextColor: black,
          dayPeriodColor: grey_light, //Background of AM/PM.
          dialHandColor: black,
          hourMinuteTextColor: black,
          hourMinuteColor: grey_light,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: white,
          headerBackgroundColor: black,
          surfaceTintColor:  Colors.transparent,
          headerForegroundColor: grey_light,
        ),
      ),
      child: child ?? Container(),
    );
  }
  
  ///
  /// Display date picker bottom sheet.
  ///
  static void selectDate(
      BuildContext context, {
        DateTime? minTime,
        DateTime? maxTime,
        required Function onConfirm,
        DateTime? currentTime,
      }) async {

      DateTime? date = await showDatePicker(
          context: context,
          firstDate: minTime ?? DateTime(1980),
          helpText: "Seleziona una data".toUpperCase(),
          cancelText: "Annulla".toUpperCase(),
          initialDate: currentTime ?? DateTime.now(),
          lastDate: maxTime ?? DateTime(3000),
          builder: dialog_theme
      );
      if (date != null) return onConfirm(date);
  }

  ///
  /// Display time picker bottom sheet.
  ///
  static void selectTime(
      BuildContext context, {
        DateTime? minTime,
        DateTime? maxTime,
        required Function onConfirm,
        DateTime? currentTime,
      }) async {
    TimeOfDay? time;
    bool valid = false;
    do {
      time = await showTimePicker(
        context: context,
        helpText: "Seleziona un'orario".toUpperCase(),
        cancelText: "Annulla".toUpperCase(),
        initialTime: TimeOfDay.fromDateTime(currentTime ?? DateTime.now()),
        builder: dialog_theme,
      );
      if(time == null) return;
      if ((minTime == null || (minTime.hour<time.hour || minTime.hour==time.hour && minTime.minute<=time.minute)) &&
          (maxTime == null || (time.hour<maxTime.hour || time.hour==maxTime.hour && time.minute<=maxTime.minute)))
        valid = true;
      else PlatformUtils.notifyErrorMessage("Inserisci un orario compreso tra 7:00 - 19:00");
    } while(!valid);
    return onConfirm(time);
  }

}