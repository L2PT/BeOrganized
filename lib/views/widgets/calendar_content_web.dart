import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:printing/printing.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/cubit/calendar_content_web/calendar_content_web_cubit.dart';
import 'package:venturiautospurghi/cubit/web/calendar_page/calendar_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/plugins/dispatcher/web.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_attention.dart';
import 'package:venturiautospurghi/views/widgets/card_event_widget.dart';

import '../../utils/pdf_utils.dart';

class CalendarContentWeb extends StatelessWidget {

  bool expandedMode = false;
  final int _backGridLength = (Constants.MAX_WORKTIME - Constants.MIN_WORKTIME + 1);
  final double _topSpace = 100;

  @override
  Widget build(BuildContext context) {
    Account account = context.read<AuthenticationBloc>().account!;
    var repository = context.read<CloudFirestoreService>();
    return new BlocProvider(
        create: (_) => CalendarContentWebCubit(repository, context, account),
        child: Column(children: [
          SizedBox(height: 10,),
          Divider(
            color: grey_light,
            thickness: 1,
            height: 0,
          ),
          BlocBuilder<WebCubit, WebCubitState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) =>
              HeaderOperatorCalendar(account),
          ),
          Expanded(
            child:
            SingleChildScrollView(child:
            Stack(children: <Widget>[
              Column(mainAxisSize: MainAxisSize.max, children: [
                ...backGrid(),
              ]),
              BlocBuilder<WebCubit, WebCubitState>(
                buildWhen: (previous, current) => previous != current,
                builder: (context, state) => Positioned(
                  child: OperatorCalendar(account, this._backGridLength, this._topSpace),
                  top: 0,
                  right: 0,
                  left: 75,
              )),
              BlocBuilder<CalendarContentWebCubit, CalendarContentWebState>(
                buildWhen: (previous, current) => previous.showHoverContainer != current.showHoverContainer,
                builder: (context, state) {
                  return Positioned(
                    child: AnimatedOpacity(
                      // If the widget is visible, animate to 0.0 (invisible).
                      // If the widget is hidden, animate to 1.0 (fully visible).
                        opacity: state.showHoverContainer ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        // The green box must be a child of the AnimatedOpacity widget.
                        child: buildContainerHover(context)),
                    top: state.posTop,
                    left: state.posLeft,
                  );
                }
              )
            ]),
              controller: context.read<WebCubit>().verticalCalendar,
            ),
          )
        ])
    );
  }

  List<Widget> backGrid() {
    return List.generate(_backGridLength, (i) {
      int n = i + Constants.MIN_WORKTIME;
      return Container(
        padding: EdgeInsets.only(left: 15),
        child: Row(
          children: <Widget>[
            Text("$n:00", style: TextStyle(color: grey_dark),),
            Expanded(child: Divider(
              color: grey_light,
              thickness:  1,
              height: 20,
              indent: 10,
              endIndent: 10,
            ),),
            SizedBox(height: 100,)
          ],
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
      );
    }).toList();
  }

  Widget buildContainerHover(BuildContext context){
    Event eventHover = context.read<CalendarContentWebCubit>().state.eventHover;
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
        border: Border.all(color: black_light, width: 2),
        color: black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Dettagli Evento: "+ eventHover.title, style: title_rev_menu,),
          SizedBox(height: 5,),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.calendar_month, size: 14),
              SizedBox(width: 5,),
              Text(_.DateUtils.hoverDateFormat(eventHover.start) == _.DateUtils.hoverDateFormat(eventHover.end)?
              _.DateUtils.hoverDateFormat(eventHover.start)+ " - " + _.DateUtils.hoverTimeFormat(eventHover.start) + " - " + _.DateUtils.hoverTimeFormat(eventHover.end):
              _.DateUtils.hoverDateFormatDiff(eventHover.start) + " - " + _.DateUtils.hoverDateFormatDiff(eventHover.end), style: white_default, ),
            ],
          ),
          SizedBox(height: 2,),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.place, size: 14),
              SizedBox(width: 5,),
              Text(eventHover.customer.address.address, style: white_default, ),
            ],
          ),
          SizedBox(height: 2,),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(EventStatus.getIcon(eventHover.status), size: 14),
              SizedBox(width: 5,),
              Text(EventStatus.getText(eventHover.status), style: white_default, ),
            ],
          )

        ],
      ),
    );
  }
}

class HeaderOperatorCalendar extends StatefulWidget {
  Account user;

  HeaderOperatorCalendar(this.user);

  @override
  State<StatefulWidget> createState() => _HeaderOperatorCalendarState(user);
}
class _HeaderOperatorCalendarState extends State<HeaderOperatorCalendar>  {

  Account user;
  Future ft = Future(() {});
  Tween<Offset> _offset = Tween(begin: Offset(1,0), end: Offset(0,0));
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Widget> _listHeaderOperatorCalendar = [];
  PDFUtils pdfUtils = new PDFUtils();

  _HeaderOperatorCalendarState(this.user);

  _addWidgetHeaderCalendarOpe(){
    _listHeaderOperatorCalendar = [];
    _listKey.currentState?.removeAllItems((context, animation) => Container());
    user.webops.forEach((operator) {
      ft = ft.then((_) {
        return Future.delayed(const Duration(milliseconds: 100), () {
          _listHeaderOperatorCalendar.add(headerOperator(operator));
          _listKey.currentState?.insertItem(_listHeaderOperatorCalendar.length -1);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    context.read<CalendarContentWebCubit>().calcWidthOpeCalendar();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _addWidgetHeaderCalendarOpe();
    });
    return Padding(padding: EdgeInsets.only(top: 10), child: SizedBox(
      height: 120,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          addOperator(context),
          Expanded(
              child:AnimatedList(
                    controller: context.read<CalendarContentWebCubit>().horizontalHeader,
                    key: _listKey,
                    initialItemCount: _listHeaderOperatorCalendar.length,
                    itemBuilder: (context, i, animation) =>
                        SlideTransition(position: animation.drive(_offset),
                            child: _listHeaderOperatorCalendar[i]),
                    scrollDirection: Axis.horizontal,)
          )
        ],
      ),
    ));
  }

  Widget addOperator(BuildContext context){
    return Column(mainAxisSize: MainAxisSize.min,children: [
      Container(
          decoration: BoxDecoration(
              color: white,
              border: Border(
                  right: BorderSide(color: grey_light, width: 1))
          ),
          height: 120,
          width: 75,
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: ElevatedButton(
            onPressed: () => PlatformUtils.navigator(context, Constants.addWebOperatorRoute, <String,dynamic>{} ),
            child: Icon(
              Icons.add,
              color: white,
              size: 35,
            ),
            style: ButtonStyle(
              shape: WidgetStateProperty.all(CircleBorder()),
              padding: WidgetStateProperty.all(EdgeInsets.all(5)),
              backgroundColor: WidgetStateProperty.all(black),
              // <-- Button color
              overlayColor:
              WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed))
                  return black_light;
                return null; // <-- Splash color
              }),
            ),
          )),
    ]);
  }

  Widget headerOperator(Account operator){
    return Container(
      height: 120,
      width: context.read<CalendarContentWebCubit>().state.widthOpeCalendar,
      padding: EdgeInsets.only(top: 5, left: 10, right: 10),
      decoration: BoxDecoration(
          color: white,
          border: Border(right: BorderSide(color: grey_light, width: 1))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(right: 10.0),
                padding: EdgeInsets.only(top: 5, left: 5, right: 8, bottom: 5),
                child: Icon(operator.supervisor? FontAwesomeIcons.userTie : FontAwesomeIcons.helmetSafety, size: 25, color: yellow,),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  color: black,
                ),
              ),
            ],
          ),
          SizedBox(height: 11,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child:RichText(
                overflow: TextOverflow.fade,
                maxLines: 1,
                softWrap: false,
                text:  TextSpan(
                  children: <InlineSpan>[
                    TextSpan(text: operator.surname.toUpperCase() + " ", style: title.copyWith(color: black, fontSize: 16,)),
                    TextSpan(text: operator.name.capitalize(),  style: subtitle.copyWith(fontSize: 16)),
                  ],
                ),)
              )
            ],
          ),
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Material(
                  color: black, // Button color
                  child: InkWell(
                    splashColor: black_light, // Splash color
                    onTap: () => Printing.layoutPdf(onLayout: (format) => pdfUtils.createDailyProgram((context.read<WebCubit>().state.calendarPageState! as ReadyCalendarPageState)
                        .selectedEventsOperator(operator.id), context.read<WebCubit>().state.calendarPageState!.calendarDate, operator)),
                    child: SizedBox(width: 30, height: 30, child: Icon(Icons.print, color: white, size: 20,)),
                  ),
                ),
              ),
              SizedBox(width: 15,),
              ClipOval(
                child: Material(
                  color: black, // Button color
                  child: InkWell(
                    splashColor: black_light, // Splash color
                    onTap: () {},
                    child: SizedBox(width: 30, height: 30, child: Icon(Icons.settings, color: white, size: 20,)),
                  ),
                ),
              ),
              SizedBox(width: 15,),
              ClipOval(
                child: Material(
                  color: black, // Button color
                  child: InkWell(
                    splashColor: black_light, // Splash color
                    onTap: () => context.read<WebCubit>().removeAccount(operator.id),
                    child: SizedBox(width: 30, height: 30, child: Icon(Icons.delete, color: white, size: 20,)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

}
class OperatorCalendar extends StatefulWidget {
  Account user;
  final int _backGridLength;
  final double _topSpace;

  OperatorCalendar(this.user, this._backGridLength, this._topSpace);

  @override
  State<StatefulWidget> createState() => _OperatorCalendarState(this.user, this._backGridLength, this._topSpace);
}

class _OperatorCalendarState extends State<OperatorCalendar>  {
  Account user;
  Future ft = Future(() {});
  Tween<Offset> _offset = Tween(begin: Offset(1,0), end: Offset(0,0));
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Widget> _listOperatorCalendar = [];

  final int _backGridLength;
  final double _topSpace;

  _OperatorCalendarState(this.user, this._backGridLength, this._topSpace);


  _addWidgetCalendarOpe(){
    int index = 0;
    _listOperatorCalendar = [];
    _listKey.currentState?.removeAllItems((context, animation) => Container());
    user.webops.forEach((operator) {
      ft = ft.then((_) {
        return Future.delayed(const Duration(milliseconds: 100), () {
          _listOperatorCalendar.add(singleOperatorCalendar(operator,index, context));
          _listKey.currentState?.insertItem(_listOperatorCalendar.length -1);
          index++;
        });
      });

    });
  }

  void changeEvent(Event event, Account operatorOld, DraggableDetails details, BuildContext context){
    Account operator = context.read<CalendarContentWebCubit>().moveEventToOperator(details);
    DateTime selectDay = context.read<WebCubit>().state.calendarPageState!.calendarDate;
    DateTime start = context.read<WebCubit>().moveEventToDate(details,selectDay, context.read<CalendarContentWebCubit>().gridHourHeight);
    DateTime end = start.add(event.end.difference(event.start));
    AttectionAlert(context, title: "CAMBIA INCARICO", text: "Stai assegnando l'incarico al operatore:",
        operator: operator, showDetailsContent: true, showDetailsContentDate: true, start: start, end: end).show().then((value) {
      if(value){
        context.read<CalendarContentWebCubit>().changeOperatorEvent(event,operatorOld, operator, start, end);
      }
    });
  }

  Widget singleOperatorCalendar(Account operator, int index, BuildContext context){
    DateTime selectDay = context.read<WebCubit>().state.calendarPageState!.calendarDate;
    List<Event> listEvent = (context.read<WebCubit>().state.calendarPageState! as ReadyCalendarPageState)
        .selectedEventsOperator(operator.id);
    DateTime _base = new DateTime(1990, 1, 1, Constants.MIN_WORKTIME, 0, 0);
    return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(child:
              Container(
                padding: EdgeInsets.only(top: 50),
                width: context.read<CalendarContentWebCubit>().state.widthOpeCalendar,
                decoration: BoxDecoration(border: Border(right: BorderSide(color: grey_light, width: 1))),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ...listEvent.map((event) {
                      if(event.start.hour >= Constants.MIN_WORKTIME && event.end.hour <= Constants.MAX_WORKTIME-1){
                        double sizeHeightBefore = context.read<CalendarContentWebCubit>().calcWidgetHeightInGrid(selectDay,firstWorkedMinute: _base.hour*60 + _base.minute, end: event.start);
                        double heightEvent = context.read<CalendarContentWebCubit>().calcWidgetHeightInGrid(selectDay,start: event.start, end: event.end);
                        List <Widget> element = <Widget>[
                          SizedBox( height: sizeHeightBefore),
                          MouseRegion(
                            child: Draggable<Event>(
                              data: event, // Passa l'evento come payload
                              maxSimultaneousDrags: 1,
                              feedback:  Opacity(
                              opacity: .3,
                              child: SizedBox(
                                width: context.read<CalendarContentWebCubit>().state.widthOpeCalendar,
                                child: CardEvent(
                                event: event,
                                height: heightEvent,
                                externalBorder: true,
                                ),)
                              ),
                              onDragEnd: (dragEvent)  => changeEvent(event, operator, dragEvent, context),
                              child: CardEvent(
                                event: event,
                                height: heightEvent,
                                externalBorder: true,
                                onTapAction: (event) => PlatformUtils.navigator(context,Constants.detailsEventViewRoute, {"objectParameter" : event}),
                              ),
                            ),
                            opaque: false,
                            onEnter: (e) => context.read<CalendarContentWebCubit>().hoverCardEnter(selectDay,index, event),
                            onExit: (e) => context.read<CalendarContentWebCubit>().hoverCardExit(),
                            cursor: WidgetStateMouseCursor.clickable,
                          ),
                        ];
                        int newBaseMinutes = _.DateUtils.getLastDailyWorkedMinute(event.end, selectDay);
                        _base = TimeUtils.truncateDate(_base, "day").add(
                            Duration(hours: newBaseMinutes ~/ 60, minutes: (newBaseMinutes % 60).toInt()));
                        return element;
                      }else{
                        return <Widget>[ Container() ];
                      }
                    }).expand((i) => i).toList()
                  ],
                ),
              ))
        ]);
  }

  @override
  Widget build(BuildContext context) {
    context.read<CalendarContentWebCubit>().calcWidthOpeCalendar();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _addWidgetCalendarOpe();
    });
    return
      Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
              height: (this._backGridLength * context.read<CalendarContentWebCubit>().gridHourHeight) + _topSpace,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: (this._backGridLength * context.read<CalendarContentWebCubit>().gridHourHeight) + _topSpace - 120, width: 0,decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: grey_light, width: 1))
                  ),  ),
                  Expanded(
                      child: RawScrollbar(
                          thumbColor: black_light,
                          radius: Radius.circular(20),
                          thickness: 10,
                          controller: context.read<CalendarContentWebCubit>().horizontalCalendar,
                          child: AnimatedList(
                            controller: context.read<CalendarContentWebCubit>().horizontalCalendar,
                            key: _listKey,
                            initialItemCount: _listOperatorCalendar.length,
                            itemBuilder: (context, i, animation) =>
                                SlideTransition(position: animation.drive(_offset),
                                    child: _listOperatorCalendar[i]),
                            scrollDirection: Axis.horizontal,))
                  )
                ],
              ))
        ],
      );
  }

}