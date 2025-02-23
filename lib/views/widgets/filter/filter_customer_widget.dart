import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/cubit/filter_customers/customer_filter_cubit.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_widget.dart';

class CustomersFilterWidget extends FilterWidget {

  final Function callbackFiltersChanged;
  final Function callbackSearchFieldChanged;
  final double maxHeightContainerExpanded;

  CustomersFilterWidget({
    double paddingTop = 20,
    double paddingTopBox = 16,
    double paddingLeftBox = 14,
    double paddingBottomBox = 14,
    double paddingRightBox = 14,
    double spaceButton = 15,
    double iconSize = 18,
    double labelSize = 14,
    String hintTextSearch = '',
    required void Function(Map<String, FilterWrapper> filters) onFiltersChanged,
    required void Function(Map<String, FilterWrapper> filters) onSearchFieldChanged,
    bool isExpandable = true,
    bool filtersBoxVisibile = false,
    this.maxHeightContainerExpanded = 400,
    bool textSearchFieldVisible = false,
  }) : callbackFiltersChanged = onFiltersChanged,
        callbackSearchFieldChanged = onSearchFieldChanged, super(
          filtersBoxVisibile: filtersBoxVisibile,
          isExpandable: isExpandable,
          hintTextSearchField: hintTextSearch,
          textSearchFieldVisible: textSearchFieldVisible,
          paddingTop: paddingTop,
          paddingTopBox: paddingTopBox,
          paddingLeftBox: paddingLeftBox,
          paddingBottomBox: paddingBottomBox,
          paddingRightBox: paddingRightBox,
          spaceButton: spaceButton,
          iconSize: iconSize,
          labelSize: labelSize,
      );

  @override
  Widget filterBox(BuildContext context) {
    const double spaceIconText = 5;
    const double spaceInput = 5;

    return new Form(
        key: context.read<CustomerFilterCubit>().formKey,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.tune),
              SizedBox(width: spaceIconText,),
              Text("FILTRI", style: subtitle_rev),
            ],
          ),
          SizedBox(height: 5.0,),
          Container(
            child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textSearchFieldVisible?
                    Padding(
                        padding: EdgeInsets.only(top: spaceInput),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.assignment_ind, color: grey, size: iconSize,),
                            SizedBox(width: spaceIconText),
                            Expanded(
                                child: TextFormField(
                                  cursorColor: white,
                                  controller: context.read<CustomerFilterCubit>().titleController,
                                  style: TextStyle(color: white, fontSize: labelSize),
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                                    hintText: 'Cerca per nome e cognome',
                                    hintStyle: subtitle.copyWith(fontSize: labelSize),
                                    border: InputBorder.none,
                                  ),
                                  onSaved: (value) => context.read<CustomerFilterCubit>().state.filters["name-surname"]!.fieldValue = value??"",
                                )),
                          ],
                        )): Container(),
                    Padding(
                        padding: EdgeInsets.only(top: spaceInput),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.mail, color: grey, size: iconSize,),
                            SizedBox(width: spaceIconText),
                            Expanded(
                                child: TextFormField(
                                  controller: context.read<CustomerFilterCubit>().emailController,
                                  cursorColor: white,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(color: white, fontSize: labelSize),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                                    hintText: 'Cerca per mail',
                                    hintStyle: subtitle.copyWith(fontSize: labelSize),
                                    border: InputBorder.none,),
                                  onSaved: (value) => context.read<CustomerFilterCubit>().state.filters["email"]!.fieldValue = value??"",
                                )),
                          ],
                        )),
                    Padding(
                        padding: EdgeInsets.only(top: spaceInput),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.phone, color: grey, size: iconSize,),
                            SizedBox(width: spaceIconText),
                            Expanded(
                                child: TextFormField(
                                  controller: context.read<CustomerFilterCubit>().phoneController,
                                  cursorColor: white,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(color: white, fontSize: labelSize),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                                    hintText: 'Cerca per telefono',
                                    hintStyle: subtitle.copyWith(fontSize: labelSize),
                                    border: InputBorder.none,),
                                  onSaved: (value) => context.read<CustomerFilterCubit>().state.filters["phone"]!.fieldValue = value??"",
                                )),
                          ],
                        )),
                    Padding(
                      padding: EdgeInsets.only(top: spaceInput),
                      child: Row(
                          children: <Widget>[
                            Icon(Icons.place, color: grey, size: iconSize,),
                            SizedBox(width: spaceIconText),
                            Expanded(
                                child: TextFormField(
                                  keyboardType: TextInputType.text,
                                  cursorColor: white,
                                  controller: context.read<CustomerFilterCubit>().addressController,
                                  style: TextStyle(color: white, fontSize: labelSize),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                                    hintText: 'Cerca per indirizzo',
                                    hintStyle: subtitle.copyWith(fontSize: labelSize),
                                    border: InputBorder.none,
                                  ),
                                  onSaved: (value) => context.read<CustomerFilterCubit>().state.filters["address"]!.fieldValue = value??"",
                                )),
                          ]),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: spaceInput),
                      child: Row(
                          children: <Widget>[
                            Icon(Icons.assignment, color: grey, size: iconSize,),
                            SizedBox(width: spaceIconText),
                            Expanded(
                                child: TextFormField(
                                  keyboardType: TextInputType.text,
                                  cursorColor: white,
                                  controller: context.read<CustomerFilterCubit>().paritaivaController,
                                  style: TextStyle(color: white, fontSize: labelSize),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                                    hintText: 'Cerca per partita iva',
                                    hintStyle: subtitle.copyWith(fontSize: labelSize),
                                    border: InputBorder.none,
                                  ),
                                  onSaved: (value) => context.read<CustomerFilterCubit>().state.filters["partitaIva"]!.fieldValue = value??"",
                                )),
                          ]),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: spaceInput),
                      child: Row(
                          children: <Widget>[
                            Icon(Icons.badge, color: grey, size: iconSize,),
                            SizedBox(width: spaceIconText),
                            Expanded(
                                child: TextFormField(
                                  keyboardType: TextInputType.text,
                                  cursorColor: white,
                                  controller: context.read<CustomerFilterCubit>().codicefiscaleController,
                                  style: TextStyle(color: white, fontSize: labelSize),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                                    hintText: 'Cerca per codice fiscale',
                                    hintStyle: subtitle.copyWith(fontSize: labelSize),
                                    border: InputBorder.none,
                                  ),
                                  onSaved: (value) => context.read<CustomerFilterCubit>().state.filters["codFiscale"]!.fieldValue = value??"",
                                )),
                          ]),
                    )
                  ],
                )),
            constraints: BoxConstraints(
              maxHeight: this.maxHeightContainerExpanded,
            ),
          ),

        ]));
  }

  @override
  void onSearchFieldTextChanged(BuildContext context, text){
    context.read<CustomerFilterCubit>().onSearchFieldTextChanged(text);
  }

  @override
  void clearFilters(BuildContext context) {
    context.read<CustomerFilterCubit>().clearFilters(
        PlatformUtils.isMobile?context.read<CustomerFilterCubit>().state.filters:
    context.read<WebCubit>().state.filters);
  }

  @override
  void applyFilters(BuildContext context){
    context.read<CustomerFilterCubit>().notifyFiltersChanged(PlatformUtils.isMobile?context.read<CustomerFilterCubit>().state.filters:
    context.read<WebCubit>().state.filters, true);
  }

  @override
  TextEditingController titleController(BuildContext context) => context.read<CustomerFilterCubit>().titleController;


  @override
  Widget build(BuildContext context) {
    return new BlocProvider(
      create: (_) => CustomerFilterCubit(callbackSearchFieldChanged, callbackFiltersChanged, PlatformUtils.isMobile? {}
              :context.read<WebCubit>().state.filters),
      child: BlocBuilder<CustomerFilterCubit, CustomersFilterState>(
          buildWhen: (previous, current) => previous != current,
          builder: (context, state) {
            super.showFiltersBox = context.read<CustomerFilterCubit>().showFiltersBox;
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