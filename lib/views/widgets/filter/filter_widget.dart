import 'dart:async';

import 'package:flutter/material.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/responsive_widget.dart';

class FilterWidget extends StatelessWidget {

  bool filtersBoxVisibile;
  void Function()? showFiltersBox;
  final String hintTextSearchField;
  final bool showActionFilters;
  bool isExpandable;
  late bool largeScreen;
  final bool textSearchFieldVisible;
  double paddingTop;
  double paddingTopBox;
  double paddingRightBox;
  double paddingLeftBox;
  double paddingBottomBox;
  double spaceButton;
  double iconSize;
  double labelSize;
  Timer? _debounce;


  FilterWidget({
    required this.filtersBoxVisibile,
    this.showFiltersBox,
    required this.isExpandable,
    required this.hintTextSearchField,
    this.showActionFilters = true,
    this.textSearchFieldVisible = false,
    this.spaceButton = 15,
    this.paddingTop = 20,
    this.paddingTopBox = 16,
    this.paddingLeftBox = 14,
    this.paddingBottomBox = 14,
    this.paddingRightBox = 14,
    this.iconSize = 16,
    this.labelSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    largeScreen = !ResponsiveWidget.isSmallScreen(context);

    Widget MobileFilter() {
      return Column(
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: this.filterAlwaysVisibleBox(context),),
          SizedBox(height: 8.0),
          this.filtersBoxVisibile ? Container(
              margin: const EdgeInsets.symmetric(
                  vertical: 8.0, horizontal: 16.0),
              padding: EdgeInsets.only(
                  top: paddingTopBox, right: paddingRightBox, bottom: paddingBottomBox, left: paddingLeftBox),
              decoration: BoxDecoration(color: black,
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              child: Column(
                children: [
                  this.filterBox(context),
                  SizedBox(height: 10.0),
                  this.showActionFilters ? this.actionFilter(context) : Container(),
                ],
              ))
              : Container(),
        ],);
    }

    Widget WebFilter() {
      return Container(
          margin: const EdgeInsets.symmetric(vertical: 5.0),
          padding: EdgeInsets.only(
              top: paddingTopBox, right: paddingRightBox, bottom: paddingBottomBox, left: paddingLeftBox),
          decoration: BoxDecoration(
              color: black,
              borderRadius: BorderRadius.all(Radius.circular(15.0))),
          child: Column(
            children: [
              this.filterBox(context),
              SizedBox(height: 10.0),
              this.showActionFilters ? this.actionFilter(context) : Container(),
            ],
          ));
    }

    return !textSearchFieldVisible?MobileFilter():WebFilter();

  }

  void _onSearchChanged(BuildContext context, String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      onSearchFieldTextChanged(context, query);
    });
  }

  Widget filterBox(BuildContext context){
    return Column();
  }

  Widget filterAlwaysVisibleBox(BuildContext context){
    return DecoratedBox(
        decoration: BoxDecoration(
            color: black, borderRadius: BorderRadius.all(Radius.circular(15.0))),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: titleController(context),
                onChanged: (s)=>_onSearchChanged(context,s),
                style: new TextStyle(color: white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: new Icon(
                    Icons.search,
                    color: white,
                  ),
                  hintText: hintTextSearchField,
                  contentPadding: EdgeInsets.only(top: 12)
                ),
              ),
            ),
            isExpandable?IconButton(
                icon: new Icon((!filtersBoxVisibile) ? Icons.tune : Icons.keyboard_arrow_up, color: white),
                onPressed: showFiltersBox
            ):Container(),
          ],
        )
    );
  }

  Widget actionFilter(BuildContext context){
    return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            child: new Text('Annulla', style: label_rev,),
            onPressed: () => this.clearFilters(context),
          ),
          SizedBox(width: spaceButton,),
          ElevatedButton(
            style: ElevatedButton.styleFrom(side: BorderSide(width: 1.0, color: white,)),
            child: new Text('FILTRA', style: button_card),
            onPressed: () => this.applyFilters(context),
          ),
        ],
    );

  }

  void onSearchFieldTextChanged(BuildContext context, String text){}

  void clearFilters(BuildContext context){}

  void applyFilters(BuildContext context){}

  TextEditingController titleController(BuildContext context) => new TextEditingController();

}