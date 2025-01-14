import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/linkmenu.dart';
import 'package:venturiautospurghi/models/page_parameter.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_customer_widget.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_events_widget.dart';

import '../../../plugins/table_calendar/table_calendar.dart';

final Map<String, LinkMenu> menuWeb = const {
  Constants.homeRoute: const LinkMenu(
      Icons.calendar_month, Colors.white, 20, "Calendario Incarichi",
      title_rev_menu),
  Constants.historyEventListRoute: const LinkMenu(
      Icons.history, Colors.white, 20, "Storico Incarichi", title_rev_menu),
  Constants.bozzeEventListRoute: const LinkMenu(
      Icons.assignment, Colors.white, 20, "Bozze", title_rev_menu),
  Constants.customerContactsListRoute: const LinkMenu(
      FontAwesomeIcons.solidAddressBook, Colors.white, 18, "Rubrica Cliente", title_rev_menu),
  /*Constants.manageUtenzeRoute: const LinkMenu(
      Icons.people, Colors.white, 20, "Gestione Utenze", title_rev_menu),*/
};

class SideMenuLayerWeb extends StatelessWidget {


  final String actionButtonRoute;
  final String textButton;
  final bool showButton;
  final IconData iconData;

  final bool showFunctionWidget;
  final FunctionalWidgetType functionalWidgetType;

  SideMenuLayerWeb(this.showButton,this.textButton,this.iconData,this.actionButtonRoute, this.functionalWidgetType, this.showFunctionWidget);


  Widget buttonAction(bool expandedMode, BuildContext context){
    return !expandedMode?
            Container( alignment: Alignment.center,
                child: IconButton(padding: EdgeInsets.all(0),onPressed: () => PlatformUtils.navigator(context, actionButtonRoute), icon: Icon(iconData, color: white, size: 40,),)):
            Column( children: [
              ElevatedButton(
                  onPressed: () => PlatformUtils.navigator(context, actionButtonRoute, <String,dynamic>{'dateSelect' : context.read<WebCubit>().state.calendarPageState!.calendarDate} ),
                  style: ButtonStyle(
                    backgroundColor:  WidgetStateProperty.all<Color>(black),
                    surfaceTintColor: WidgetStateProperty.all<Color>(black),
                    shadowColor: WidgetStateProperty.all<Color>(Colors.black),
                    elevation: WidgetStateProperty.all<double>(4.0),
                    padding:
                    WidgetStateProperty.all(EdgeInsets.all(22)),
                    shape: WidgetStateProperty.all<
                        RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: BorderSide(
                            width: 1.0,
                            color: white,
                          )),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        iconData,
                        color: white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        textButton,
                        style: button_card.copyWith(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )),
              SizedBox(height:15),
            ],);
  }

  MapEntry<String, Widget> _buildMenuNavigation(String route, bool expandendMode, LinkMenu view, BuildContext context) {
    final GoRouterState stateRoute = GoRouterState.of(context);
    return new MapEntry(
        route,
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              context.go(route);
            },
            child: Container(
              margin: EdgeInsets.only(top: 15),
              child: expandendMode
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    view.iconLink,
                    color: stateRoute.uri.toString() == route
                        ? yellow
                        : view.colorIcon,
                    size: view.sizeIcon,
                    semanticLabel: 'Icon menu',
                  ),
                  SizedBox(width: 15.0),
                  Text(
                    view.textLink,
                    style: view.styleText,

                  )
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    view.iconLink,
                    color: stateRoute.uri.toString() == route
                        ? yellow
                        : view.colorIcon,
                    size: view.sizeIcon * 2,
                    semanticLabel: 'Icon menu',
                  ),
                ],
              ),
            ),
          ),
        )
    );
  }

  Widget getFunctionWidget(BuildContext tex){
    switch(this.functionalWidgetType){
      case FunctionalWidgetType.calendar:
        return BlocBuilder<WebCubit, WebCubitState>(
            buildWhen: (previous, current) => previous.calendarPageState!.calendarDate != current.calendarPageState!.calendarDate,
            builder: (context, state) =>
                TableCalendar(
            rowHeight: 25,
            locale: 'it_IT',
            calendarController: context.read<WebCubit>().calendarPageCubit.calendarController,
            initialSelectedDay: context.read<WebCubit>().calendarPageCubit.newDate,
            initialCalendarFormat: CalendarFormat.month,
            formatAnimation: FormatAnimation.slide,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableGestures: AvailableGestures.none,
            availableCalendarFormats: {CalendarFormat.month: ''},
            onDaySelected: (date, events) {
              context.read<WebCubit>().calendarPageCubit.selectCalendarDate(date);
            },
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontWeight: FontWeight.normal, color: Colors.white, fontSize: 10),
              weekendStyle: TextStyle(fontWeight: FontWeight.normal, color: Colors.white, fontSize: 10),
            ),
            calendarStyle: CalendarStyle(
              weekendStyle: TextStyle(fontWeight: FontWeight.normal, color: Colors.white, fontSize: 9),
              weekdayStyle: TextStyle(fontWeight: FontWeight.normal, color: Colors.white, fontSize: 9),
              outsideStyle: TextStyle(fontWeight: FontWeight.normal, color: grey_dark, fontSize: 8),
            ),
            builders: CalendarBuilders(
              todayDayBuilder: (context, date, _) {
                return Container(
                  margin: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: grey_light,
                    borderRadius: BorderRadius.circular(100.0),
                  ),
                  child: Center(child: Text(
                      '${date.day}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: black, fontSize: 10)
                  ),
                  ),
                );
              },
              selectedDayBuilder: (context, date, _) {
                return Container(
                  margin: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: yellow,
                    borderRadius: BorderRadius.circular(100.0),
                  ),
                  child: Center(child: Text(
                      '${date.day}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: black, fontSize: 10)
                  ),
                  ),
                );
              },
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(fontWeight: FontWeight.bold, color: white, fontSize: 12),
              leftChevronPadding: EdgeInsets.all(5),
              rightChevronPadding:EdgeInsets.all(5),
              leftChevronIcon: Icon(Icons.navigate_before, color: white,),
              rightChevronIcon: Icon(Icons.navigate_next, color: white, ),
            ),)
          );break;
      case FunctionalWidgetType.filterEvent:
        return BlocBuilder<WebCubit, WebCubitState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) =>
                EventsFilterWidget(
                  hintTextSearch: 'Cerca gli interventi',
                  onSearchFieldChanged: (filter) => context.read<WebCubit>().onFiltersChangedEvent(filter, GoRouterState.of(tex).fullPath??''),
                  onFiltersChanged: (filter) => context.read<WebCubit>().onFiltersChangedEvent(filter, GoRouterState.of(tex).fullPath??''),
                  maxHeightContainerExpanded: MediaQuery.of(context).size.height-270,
                  textSearchFieldVisible: true,
                  paddingTop: 10,
                  paddingBottomBox: 0,
                  paddingLeftBox: 0,
                  paddingRightBox: 0,
                  paddingTopBox: 0,
                  spaceButton: 10,
                ));
      case FunctionalWidgetType.FilterOperator:
        return Container();
      case FunctionalWidgetType.FilterCustomer:
        return BlocBuilder<WebCubit, WebCubitState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) =>
                 CustomersFilterWidget(
                  hintTextSearch: 'Cerca i clienti',
                  onSearchFieldChanged: context.read<WebCubit>().contactsPageCubit.onFiltersChangedCustomer,
                  onFiltersChanged: context.read<WebCubit>().contactsPageCubit.onFiltersChangedCustomer,
                  maxHeightContainerExpanded: MediaQuery.of(context).size.height-270,
                  textSearchFieldVisible: true,
                  paddingTop: 10,
                  paddingBottomBox: 0,
                  paddingLeftBox: 0,
                  paddingRightBox: 0,
                  paddingTopBox: 0,
                  spaceButton: 10,
              ));
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {

    return new BlocBuilder<WebCubit, WebCubitState>(
        buildWhen: (previous, current) => previous.expandedMode != current.expandedMode,
        builder: (context, state) {
          return AnimatedContainer(
            padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
            color: black,
            width: state.expandedMode?200:70,
            duration: const Duration(milliseconds: 550),
            child: Column(
              children: [
                Expanded(
                    child: Column(
                      children: [
                        new Text(state.expandedMode?"BeOrganized":"BO", style: title_rev_web,),
                        SizedBox(height:30),
                        this.showButton? buttonAction(state.expandedMode, context):Container(),
                        this.showFunctionWidget && state.expandedMode?getFunctionWidget(context):Container(),
                        state.expandedMode?Divider(
                          color: grey_light,
                          thickness: 1,
                          height: 20,
                        ):Container(),
                        Expanded(
                          child: new ListView(
                              physics: new BouncingScrollPhysics(),
                              children: menuWeb
                                  .map((route, linkMenu) => _buildMenuNavigation(route, state.expandedMode, linkMenu, context))
                                  .values
                                  .toList()),),
                        Container(
                          alignment: Alignment.centerRight,
                          child: IconButton(onPressed: context.read<WebCubit>().showExpandedBox, icon: Icon(state.expandedMode?Icons.navigate_before:Icons.navigate_next, color: white,size: 35)),
                        )
                      ],
                    )

                ),
              ],
            ),);
        },
      );

  }

}