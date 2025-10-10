import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;
import 'package:venturiautospurghi/utils/global_methods.dart';

part 'filter_operators_state.dart';

class OperatorsFilterCubit extends Cubit<OperatorsFilterState> {
  final Function callbackFiltersChanged;
  final Function callbackSearchFieldChanged;
  late TextEditingController titleController;

  OperatorsFilterCubit(this.callbackSearchFieldChanged, this.callbackFiltersChanged) : super(OperatorsFilterState()){
    titleController = new TextEditingController();
  }

  void showFiltersBox() {
    emit(state.assign(filtersBoxVisibile:!state.filtersBoxVisibile));
  }

  setSearchDate(DateTime date) {
    Map<String, FilterWrapper> filters = Map.from(state.filters);
    filters["date"] = filters["date"]!.update(TimeUtils.truncateDate(date, "day").add(Duration(hours: filters["date"]!.fieldValue?.hour??0, minutes:filters["date"]!.fieldValue?.minute??0)));
    emit(state.assign(filters: filters));
    notifyFiltersChanged();
  }

  setSearchTime(TimeOfDay time) {
    Map<String, FilterWrapper> filters = Map.from(state.filters);
    filters["date"] = filters["date"]!.update(TimeUtils.truncateDate(state.filters["date"]!.fieldValue??_.DateUtils.now(), "day")
        .add(Duration(hours: DateTimeField.convert(time)!.hour, minutes: DateTimeField.convert(time)!.minute)));
    emit(state.assign(filters: filters));
    notifyFiltersChanged();
  }

  void onSearchFieldTextChanged(String text){
    state.filters["name"]!.fieldValue = text;
    callbackSearchFieldChanged(state.filters);
  }

  void notifyFiltersChanged(){
    callbackFiltersChanged(state.filters);
  }

}