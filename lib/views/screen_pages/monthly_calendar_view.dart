/*
THIS IS THE MAIN PAGE OF THE OPERATOR
-l'appBar contiene menu a sinistra, titolo al centro, profilo a destra
-in alto c'è una riga di giorni della settimana selezionabili
-(R)al centro e in basso c'è una grglia oraria dove sono rappresentati gli eventi dell'operatore corrente del giorno selezionato in alto
-(o)al centro e in basso c'è una grglia oraria dove sono rappresentati i propri eventi del giorno selezionato in alto
 */
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/cubit/monthly_calendar/monthly_calendar_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/plugins/dispatcher/mobile.dart';
import 'package:venturiautospurghi/plugins/table_calendar/table_calendar.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class MonthlyCalendar extends StatefulWidget {
  final DateTime? month;
  final Account? operator;

  MonthlyCalendar([this.month, this.operator]);

  @override
  _MonthlyCalendarViewState createState() => _MonthlyCalendarViewState(this.month,this.operator);

}

class _MonthlyCalendarViewState extends State<MonthlyCalendar> with TickerProviderStateMixin {
  final DateTime? month;
  final Account? operator;

  _MonthlyCalendarViewState(this.month, this.operator);

  @override
  Widget build(BuildContext context) {
    CloudFirestoreService repository = context.read<CloudFirestoreService>();
    Account account = context.select((AuthenticationBloc bloc)=>bloc.account!);

    return new BlocProvider(
        create: (_) => MonthlyCalendarCubit(repository, account, operator, month),
        child: Material(
            elevation: 12.0,
            borderRadius: new BorderRadius.only(
                topLeft: new Radius.circular(16.0),
                topRight: new Radius.circular(16.0)),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                    child:
                    _contentTableCalendar(this)
                ),
              ],
            )));
  }
}

class _contentTableCalendar extends StatelessWidget {
    var _animation;
    var _animationController;

    _contentTableCalendar(_MonthlyCalendarViewState ticker){
      _animationController = AnimationController(duration: const Duration(milliseconds: 400), vsync: ticker);
      _animation = Tween(begin: 0.0, end: 1.0,).animate(_animationController);
    }

    @override
    Widget build(BuildContext context) {
      Account account = context.read<AuthenticationBloc>().account!;
      _animationController.forward();

      return BlocBuilder<MonthlyCalendarCubit, MonthlyCalendarState>(

          buildWhen: (previous, current) => (previous.runtimeType) != (current.runtimeType) ||
              previous.eventsMap != current.eventsMap  ,
          builder: (context, state) {
            return !(state is MonthlyCalendarReady) ? Center(child: CircularProgressIndicator()) :
             TableCalendar(
              rowHeight: 85,
              locale: 'it_IT',
              calendarController: context.read<MonthlyCalendarCubit>().calendarController,
              events: state.eventsMap,
              initialCalendarFormat: CalendarFormat.month,
              formatAnimation: FormatAnimation.slide,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableGestures: AvailableGestures.horizontalSwipe,
              availableCalendarFormats: {CalendarFormat.month: ''},
              initialSelectedDay: state.selectedMonth,
              calendarStyle: CalendarStyle(markersMaxAmount: 99),
              headerStyle: HeaderStyle(rightChevronIcon: Icon(null)),
              builders: CalendarBuilders(
                selectedDayBuilder: (context, date, _) {
                  return FadeTransition(
                    opacity: _animation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: black,
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Center(
                        child: Text('${date.day}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: white,
                                fontSize: 18)),
                      ),
                    ),
                  );
                },
                todayDayBuilder: (context, date, _) {
                  return Container(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                    decoration: BoxDecoration(
                      color: grey_light,
                      borderRadius: BorderRadius.circular(100.0),
                    ),
                    child: Center(
                      child: Text('${date.day}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                              fontSize: 18)),
                    ),
                  );
                },
                markersBuilder: (context, date, events, holidays) {
                  final children = <Widget>[];
                  if (events.isNotEmpty) {
                    children.add(Positioned(
                      top: 1,
                      right: 1,
                      child: _buildEventsMarker(date, events),
                    ));
                  }
                  return children;
                },
              ),
              onDaySelected: (date, events) {
                account.supervisor ?
                PlatformUtils.navigator(context, Constants.dailyCalendarRoute, {'day' : date, 'operator' : context.read<MonthlyCalendarCubit>().operator}) :
                PlatformUtils.navigator(context, Constants.homeRoute, {'day' : date, 'operator' : account});
                _animationController.forward(from: 0.0);
                _animationController.dispose();
              },
              selectNext: context.read<MonthlyCalendarCubit>().selectNextorPrevious,
              selectPrevious: context.read<MonthlyCalendarCubit>().selectNextorPrevious,
            );
          });
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20),
        color: black,
      ),
      width: 25,
      height: 25,
      margin: EdgeInsets.only(top: 5),
      child:
          Center(
            child: Text(
              '${events.length}',
              style: TextStyle().copyWith(
                color: Colors.white,
                fontSize: 16.0,
              ),
            ),
          )
    );
  }

}