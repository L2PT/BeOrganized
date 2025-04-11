import 'package:flutter/material.dart';

enum FunctionalWidgetType { calendar, filterEvent, FilterOperator, FilterCustomer, FilterAccount }

class PageParameter {

  //SideMenu parameter
  final IconData _icon;
  final String _actionButtonRoute;
  final String _textButton;
  final bool _showButton;
  final bool _showFunctionWidget;
  final FunctionalWidgetType _functionalWidgetType;

  //HeaderMenu parameter
  bool _showBoxCalendar = false;

  PageParameter(this._icon, this._actionButtonRoute, this._textButton,
      this._functionalWidgetType, this._showBoxCalendar, this._showButton, this._showFunctionWidget);

  IconData get iconLink => _icon;
  String get textButton => _textButton;
  bool get showButton => _showButton;
  bool get showFunctionWidget => _showFunctionWidget;
  String get actionButtonRoute => _actionButtonRoute;
  FunctionalWidgetType get functionalWidgetType => _functionalWidgetType;
  bool get showBoxCalendar => _showBoxCalendar;

}