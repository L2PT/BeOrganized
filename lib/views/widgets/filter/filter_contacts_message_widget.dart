import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/cubit/filter_operators/filter_operators_cubit.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_widget.dart';
import 'package:venturiautospurghi/views/widgets/responsive_widget.dart';

class ContactsMessageFilterWidget extends FilterWidget {

  final Function callbackFiltersChanged;
  final Function callbackSearchFieldChanged;

  ContactsMessageFilterWidget({
    double paddingTop = 25,
    double paddingHorizontal = 8.0,
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
        paddingHorizontal: paddingHorizontal,
      );

  @override
  Widget filterBox(BuildContext context) {
    return  Container();
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