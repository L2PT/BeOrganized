/*
THIS IS THE MAIN PAGE OF THE OPERATOR
-l'appBar contiene menu a sinistra, titolo al centro
-in alto c'è una riga di giorni della settimana selezionabili
-(R)al centro e in basso c'è una grglia oraria dove sono rappresentati gli eventi dell'operatore corrente del giorno selezionato in alto
-(O)al centro e in basso c'è una grglia oraria dove sono rappresentati i propri eventi del giorno selezionato in alto
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/bloc/mobile_bloc/mobile_bloc.dart';
import 'package:venturiautospurghi/cubit/daily_calendar/daily_calendar_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/models/layout/event_layout.dart';
import 'package:venturiautospurghi/models/layout/group_overlapping.dart';
import 'package:venturiautospurghi/plugins/dispatcher/mobile.dart';
import 'package:venturiautospurghi/plugins/table_calendar/table_calendar.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/card_event_widget.dart';
import 'package:venturiautospurghi/views/widgets/no_events_widget.dart';

class DailyCalendar extends StatefulWidget {
  final DateTime? day;
  final Account? operator;

  DailyCalendar([this.day, this.operator]);

  @override
  _DailyCalendarViewState createState() => _DailyCalendarViewState(day, operator);
}

class _DailyCalendarViewState extends State<DailyCalendar> with TickerProviderStateMixin {
  final DateTime? _day;
  final Account? _operator;

  _DailyCalendarViewState(this._day, this._operator);

  @override
  Widget build(BuildContext context) {
    CloudFirestoreService repository = context.read<CloudFirestoreService>();
    Account account = context.select((AuthenticationBloc bloc)=>bloc.account!);

    Widget content = Column(
        mainAxisSize: MainAxisSize.max,
        children:
        <Widget>[
          _rowCalendar(this),
          const SizedBox(height: 8.0),
          _verticalEventsGrid(this)
        ]);

    return new BlocProvider(
        create: (_) => DailyCalendarCubit(repository, account, _operator, _day),
        child: Material(
            elevation: 12.0,
            borderRadius: new BorderRadius.only(
                topLeft: new Radius.circular(16.0),
                topRight: new Radius.circular(16.0)),
            child: content
        ));
  }
}

class _rowCalendar extends StatelessWidget {
  var _animationController;
  var _animation;

  _rowCalendar(_DailyCalendarViewState ticker){
    _animationController = AnimationController(duration: const Duration(milliseconds: 400), vsync: ticker);
    _animation = Tween(begin: 0.0, end: 1.0,).animate(_animationController);
  }

  @override
  Widget build(BuildContext context) {
    _animationController.forward();

    return BlocBuilder<DailyCalendarCubit, DailyCalendarState>(
      buildWhen: (previous, current) => (previous.runtimeType) != (current.runtimeType) ||
          previous.eventsMap != current.eventsMap || previous.selectedDay != current.selectedDay,
      builder: (context, state) {
        return TableCalendar(
          locale: 'it_IT',
          calendarController: context.read<DailyCalendarCubit>().calendarController,
          events: state.eventsMap,
          initialCalendarFormat: CalendarFormat.week,
          formatAnimation: FormatAnimation.slide,
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableGestures: AvailableGestures.horizontalSwipe,
          availableCalendarFormats: {CalendarFormat.week: ''},
          initialSelectedDay: state.selectedDay,
          builders: CalendarBuilders(
              selectedDayBuilder: (context, date, _) {
                return  FadeTransition(
                  opacity: _animation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: black,
                        borderRadius: BorderRadius.circular(10.0)
                    ),
                    child: Center(
                      child: Text(
                          '${date.day}',
                          style: const TextStyle(fontWeight: FontWeight.bold,
                              color: white,
                              fontSize: 18)
                      ),
                    ),
                  ),
                );
              },
              markersBuilder: (context, date, events, holidays) {
                final children = <Widget>[];
                return children;
              },
              todayDayBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: grey_light,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Center(child:
                  Text( '${date.day}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333), fontSize: 18)
                  ),
                  ),
                );
              },
              holidayDayBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: green,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Center(child:
                  Text( '${date.day}', style: const TextStyle(fontWeight: FontWeight.bold, color: white, fontSize: 18)
                  ),
                  ),
                );
              }
          ),
          onDaySelected: (date, events) {
            context.read<DailyCalendarCubit>().onDaySelected(date);
            //_animationController.forward(from: 0.0);
          },//    if(state is DailyCalendarReady)
          selectMonthCalendar: () {
            context.read<MobileBloc>().add(NavigateEvent(Constants.monthlyCalendarRoute, {'month': context.read<DailyCalendarCubit>().state.selectedDay, 'operator' : context.read<DailyCalendarCubit>().operator}));
            _animationController.dispose();
          },
        );
      },
    );
  }

}

class _verticalEventsGrid extends StatelessWidget {
  var _animationController;

  _verticalEventsGrid(_DailyCalendarViewState ticker) {
    _animationController = AnimationController(duration: const Duration(milliseconds: 400), vsync: ticker);
  }

  /// Crea un widget per eventi sovrapposti usando Stack
  Widget _buildOverlappingEventsWidget(
      OverlappingGroup group,
      BuildContext context,
      Account account,
      DateTime selectedDay,
      int backGridHourSpan,
      double gridHourHeight,
      DateTime baseTime,
      double containerWidth,
      ) {
    // Calcola i layout per tutti gli eventi del gruppo
    List<EventLayout> layouts = group.calculateGroupLayout(
      containerWidth,
      selectedDay,
      gridHourSpan: backGridHourSpan,
      gridHourHeight: gridHourHeight,
      baseTime: baseTime,
    );

    // Trova l'evento con il top più alto per posizionare il container
    double minTop = layouts.map((l) => l.top).reduce((a, b) => a < b ? a : b);
    double maxBottom = layouts.map((l) => l.top + l.height).reduce((a, b) => a > b ? a : b);
    double totalHeight = maxBottom - minTop;

    return Container(
      height: totalHeight,
      child: Stack(
        children: layouts.map((layout) {
          return Positioned(
            left: layout.left,
            top: layout.top - minTop, // Relativo al container
            width: layout.width,
            height: layout.height,
            child: CardEvent(
              event: layout.event,
              height: layout.height,
              externalBorder: true,
              onTapAction: (event) => PlatformUtils.navigator(
                context,
                Constants.detailsEventViewRoute,
                event,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Account account = context.read<AuthenticationBloc>().account!;
    int backGridHourSpan = context.select((DailyCalendarCubit cubit) => cubit.state.gridHourSpan);
    double gridHourHeight = context.select((DailyCalendarCubit cubit) => cubit.state.gridHourHeight);
    bool allDayEvent = context.select((DailyCalendarCubit cubit) => cubit.state.allDayEvent);

    late int _backGridLength;
    late double _barHourHeight;
    late DateTime _base;
    late DateTime _top;

    List<Widget> backGrid() =>
        List.generate(_backGridLength, (i) {
          int n = ((i) * backGridHourSpan) + Constants.MIN_WORKTIME;
          return Row(children: <Widget>[Expanded(
              flex: 2,
              child: Container(
                  padding: EdgeInsets.only(left: 20),
                  height: gridHourHeight,
                  child: Center(
                    child: Text("$n:00", style: TextStyle(color: grey_dark),),)
              )
          ),
            Expanded(
                flex: 8,
                child: Column(children: <Widget>
                [Container(
                      height: _barHourHeight,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 4, color: grey_light2),
                        ),
                      )
                  ), Container(
                    height: _barHourHeight,
                  )
                ]
                )
            ),
          ]
          );
        }).toList();

    List<Widget> frontEventList() {
      List<Event> events = (context.read<DailyCalendarCubit>().state as DailyCalendarReady).selectedEvents();
      List<OverlappingGroup> overlappingEvent = (context.read<DailyCalendarCubit>().state as DailyCalendarReady)
          .selectedOverlapping();


      if (backGridHourSpan == 0 && allDayEvent) {
        // Evento che dura tutto il giorno
        return <Widget>[
          SizedBox(height: 5),
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(padding: EdgeInsets.only(left: 10, bottom: 10),
                  child: Text("Incarico per tutto il giorno", style: subtitle.copyWith(fontSize: 18,),),)
              ]
          ),
          Row(children: <Widget>[
            Expanded(
                flex: 8,
                child: CardEvent(
                  event: events[0],
                  height: gridHourHeight,
                  externalBorder: true,
                  showEventDetails: true,
                  onTapAction: (event) => PlatformUtils.navigator(context, Constants.detailsEventViewRoute, event),
                )
            ),
          ])
        ];
      }

      if (backGridHourSpan == 0) {
        // Lista di eventi continua (senza griglia oraria)
        return <Widget>[
          SizedBox(height: 5),
          ...events.map((event) => Padding(
              padding: EdgeInsets.symmetric(vertical: 5.0),
              child: Row(children: <Widget>[
                Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.only(right: 40),
                      height: gridHourHeight,
                      child: account.supervisor ? Icon(EventStatus.getIcon(event.status), color: black) : Container(),
                    )
                ),
                Expanded(
                  flex: 8,
                  child: CardEvent(
                    event: event,
                    height: gridHourHeight,
                    externalBorder: true,
                    showEventDetails: true,
                    onTapAction: (event) => PlatformUtils.navigator(context, Constants.detailsEventViewRoute, event),
                  ),
                ),
              ])))
        ];
      }
      List<Widget> widgets = [SizedBox(height: _barHourHeight)];

      // Ottieni la larghezza del container per gli eventi (80% della larghezza totale)
      double containerWidth = MediaQuery.of(context).size.width * 0.8;

      DateTime currentBase = _base;

      for (OverlappingGroup group in overlappingEvent) {
        group.calculateAndAssignColumns();

        // Calcola la posizione di inizio del gruppo
        Event firstEvent = group.events.first;
        double spacingHeight = context.read<DailyCalendarCubit>().calcWidgetHeightInGrid(
            firstWorkedMinute: currentBase.hour * 60 + currentBase.minute,
            end: firstEvent.start
        );

        // Aggiungi spazio prima del gruppo
        if (spacingHeight > 0) {
          widgets.add(SizedBox(height: spacingHeight));
        }

        // Aggiungi il widget del gruppo sovrapposto
        widgets.add(
          Row(
            children: [
              // Colonna per l'icona di stato (solo per il primo evento del gruppo)
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.only(right: 40),
                  height: group.events.map((e) =>
                      context.read<DailyCalendarCubit>().calcWidgetHeightInGrid(
                          start: e.start,
                          end: e.end
                      )
                  ).reduce((a, b) => a > b ? a : b), // Altezza dell'evento più alto nel gruppo
                  child: account.supervisor
                      ? Icon(EventStatus.getIcon(group.events.first.status), color: black)
                      : Container(),
                ),
              ),
              // Container per gli eventi sovrapposti
              Expanded(
                flex: 8,
                child: _buildOverlappingEventsWidget(
                  group,
                  context,
                  account,
                  context.read<DailyCalendarCubit>().state.selectedDay,
                  backGridHourSpan,
                  gridHourHeight,
                  currentBase,
                  containerWidth,
                ),
              ),
            ],
          ),
        );

        // Aggiorna la base per il prossimo gruppo
        Event lastEvent = group.events.last;
        int newBaseMinutes = _.DateUtils.getLastDailyWorkedMinute(
            lastEvent.end,
            context.read<DailyCalendarCubit>().state.selectedDay
        );
        currentBase = TimeUtils.truncateDate(currentBase, "day").add(
            Duration(hours: newBaseMinutes ~/ 60, minutes: (newBaseMinutes % 60).toInt())
        );
      }

      // Aggiungi spazio finale
      widgets.add(SizedBox(
          height: (((_top.hour * 60 + _top.minute) - (currentBase.hour * 60 + currentBase.minute)) / 60) /
              backGridHourSpan * gridHourHeight
      ));

      return widgets;
    }

    return BlocBuilder<DailyCalendarCubit, DailyCalendarState>(
        buildWhen: (previous, current) => previous != current,
        builder: (context, state) {
          if (!(state is DailyCalendarReady))
            return Center(child: CircularProgressIndicator());
          if((state).selectedEvents().isEmpty)
            return Expanded( child: GestureDetector(
              // Gestione dello swipe
                onHorizontalDragEnd: (DragEndDetails details) {
                  // Calcola la velocità dello swipe
                  const double minSwipeVelocity = 500.0;
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! > minSwipeVelocity) {
                      // Swipe verso destra - giorno precedente
                      context.read<DailyCalendarCubit>().selectNextorPrevious(false);
                    } else if (details.primaryVelocity! < -minSwipeVelocity) {
                      // Swipe verso sinistra - giorno successivo
                      context.read<DailyCalendarCubit>().selectNextorPrevious(true);
                    }
                  }
                }, child: Padding(
                padding: EdgeInsets.all(20),
                child: EmptyEvent(
                  onPressedFunction: () {
                    context.read<MobileBloc>().add( NavigateEvent(Constants.monthlyCalendarRoute, {'month': context.read<DailyCalendarCubit>().state.selectedDay, 'operator' : context.read<DailyCalendarCubit>().operator}));
                    _animationController.dispose();
                  },
                  titleMessage: 'Nessun intervento in programma per questa data',
                  subtitleMessage: "Controlla i tuoi incarichi",
                ))));

          _backGridLength = backGridHourSpan == 0 ? 0 : (Constants.MAX_WORKTIME - Constants.MIN_WORKTIME + 1) ~/ backGridHourSpan;
          _barHourHeight = gridHourHeight / 2;
          _base = new DateTime(1990, 1, 1, Constants.MIN_WORKTIME, 0, 0);
          _top = new DateTime(1990, 1, 1, Constants.MAX_WORKTIME, 0, 0);
          return Expanded( child: GestureDetector(
              // Gestione dello swipe
              onHorizontalDragEnd: (DragEndDetails details) {
            // Calcola la velocità dello swipe
            const double minSwipeVelocity = 500.0;
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! > minSwipeVelocity) {
                // Swipe verso destra - giorno precedente
                context.read<DailyCalendarCubit>().selectNextorPrevious(false);
              } else if (details.primaryVelocity! < -minSwipeVelocity) {
                // Swipe verso sinistra - giorno successivo
                context.read<DailyCalendarCubit>().selectNextorPrevious(true);
              }
            }
          }, child:ListView(
              children: <Widget>[
                Stack(
                    children: <Widget>[
                      backGridHourSpan == 0 ? Container(height: 20) :
                      Column(
                          mainAxisSize: MainAxisSize.max,
                          children: backGrid()
                      ),
                      state.selectedEvents().length <= 0 ? Container(height: 20) :
                      Column(
                          mainAxisSize: MainAxisSize.max,
                          children: frontEventList()
                      )
                    ])
              ])));
        });
  }
}