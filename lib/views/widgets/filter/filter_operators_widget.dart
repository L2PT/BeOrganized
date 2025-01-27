import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:venturiautospurghi/cubit/filter_operators/filter_operators_cubit.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_widget.dart';
import 'package:venturiautospurghi/views/widgets/platform_datepicker.dart';
import 'package:venturiautospurghi/views/widgets/responsive_widget.dart';

class OperatorsFilterWidget extends FilterWidget {

  final Function callbackFiltersChanged;
  final Function callbackSearchFieldChanged;

  OperatorsFilterWidget({
    double paddingTop = 25,
    String hintTextSearch = '',
    required void Function(Map<String, FilterWrapper> filters) onFiltersChanged,
    required void Function(Map<String, FilterWrapper> filters) onSearchFieldChanged,
    bool isExpandable = true,
    bool filtersBoxVisibile = false,
  }) : callbackFiltersChanged = onFiltersChanged,
        callbackSearchFieldChanged = onSearchFieldChanged, super(
      filtersBoxVisibile: filtersBoxVisibile,
      isExpandable: isExpandable,
      hintTextSearchField: hintTextSearch,
      showActionFilters: false,
      paddingTop: paddingTop,
  );

  @override
  Widget filterBox(BuildContext context) {
    DateFormat formatDate = DateFormat('E d MMM y','it_IT');
    return  Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.tune),
              SizedBox(width: 5,),
              Text("FILTRA", style: subtitle_rev),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 3.0),
            child: Text("Operatori liberi", style: subtitle_rev.copyWith(fontWeight: FontWeight.normal)),
          ),
          Padding(
              padding: EdgeInsets.only(top: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Row(children: [
                      Icon(Icons.date_range),
                      SizedBox(width: 5),
                      GestureDetector(
                        child: Text(context.read<OperatorsFilterCubit>().state.filters["date"] != null ?
                        formatDate.format(context.read<OperatorsFilterCubit>().state.filters["date"]!.fieldValue??DateTime.now()):'Data inizio', style: time_card),
                        onTap: () =>
                            PlatformDatePicker.selectDate(context,
                              maxTime: DateTime(3000),
                              currentTime: context.read<OperatorsFilterCubit>().state.filters["date"]!.fieldValue??DateTime.now(),
                              onConfirm: (date) => context.read<OperatorsFilterCubit>().setSearchDate(date),
                            ),
                      ),
                    ],
                  ),
                  Row( children: [
                    Icon(Icons.watch_later),
                    SizedBox(width: 5),
                    GestureDetector(
                      child: Text((context.read<OperatorsFilterCubit>().state.filters["date"]!.fieldValue??DateTime.now()).toString().split(' ').last.split('.').first.substring(0, 5), style: time_card),
                      onTap: () =>
                          PlatformDatePicker.selectTime(context,
                            currentTime: context.read<OperatorsFilterCubit>().state.filters["date"]!.fieldValue,
                            onConfirm: (time) => context.read<OperatorsFilterCubit>().setSearchTime(time),
                          ),
                    )
                  ]),
                ],
              ))
        ]);
  }

  @override
  void onSearchFieldTextChanged(BuildContext context, text){
    context.read<OperatorsFilterCubit>().onSearchFieldTextChanged(text);
  }

  @override
  TextEditingController titleController(BuildContext context) => context.read<OperatorsFilterCubit>().titleController;

  @override
  Widget build(BuildContext context) {
    largeScreen = !ResponsiveWidget.isSmallScreen(context);

    return new BlocProvider(
      create: (_) => OperatorsFilterCubit(callbackSearchFieldChanged, callbackFiltersChanged),
      child: BlocBuilder<OperatorsFilterCubit, OperatorsFilterState>(
          builder: (context, state) {
            super.showFiltersBox = context.read<OperatorsFilterCubit>().showFiltersBox;
            super.filtersBoxVisibile = state.filtersBoxVisibile;
            if(!state.isLoading()){
              return !textSearchFieldVisible?
              Padding(
                padding: EdgeInsets.only(top: paddingTop),
                child: super.build(context),
              ): super.build(context);
            } else return CircularProgressIndicator();
          }
      ),);
  }

}