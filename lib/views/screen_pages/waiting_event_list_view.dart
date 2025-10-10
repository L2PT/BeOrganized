import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/cubit/waiting_event_list/waiting_event_list_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_refuse.dart';
import 'package:venturiautospurghi/views/widgets/card_event_widget.dart';
import 'package:venturiautospurghi/views/widgets/loading_screen.dart';
import 'package:venturiautospurghi/views/widgets/no_events_widget.dart';

class WaitingEventList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    CloudFirestoreService repository = context.read<CloudFirestoreService>();
    Account account = context.select((AuthenticationBloc bloc)=>bloc.account!);

    return new BlocProvider(
        create: (_) => WaitingEventListCubit(repository, account),
        child: Material(
            elevation: 12.0,
            borderRadius: new BorderRadius.only(
                topLeft: new Radius.circular(16.0),
                topRight: new Radius.circular(16.0)),
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded( child: _eventList())
                ],
              ),
            ),
        )
    );
  }
}

class _eventList extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    late List<List<Event>> eventsGroupedByDay;

    void _onCalendarPressed(){
      DateTime date = _.DateUtils.now();
      PlatformUtils.navigator(context, Constants.monthlyCalendarRoute, {'month' : date, 'operator' : null});
    }

    Widget buildGroupEventList() => ListView.builder(
      physics: BouncingScrollPhysics(),
      itemCount: eventsGroupedByDay.length,
      itemBuilder: (context, index) => _listGroup(eventsGroupedByDay[index]),);

    Widget noContent =  Container(child: EmptyEvent(
      onPressedFunction: _onCalendarPressed,
      titleMessage: 'Nessun incarico in sospeso',
      subtitleMessage: "Controlla i tuoi incarichi accettati",
    ),);


    return BlocBuilder<WaitingEventListCubit, WaitingEventListState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        if(state is ReadyEvents) {
          if(state.events.length > 0) {
            eventsGroupedByDay = state.events.groupBy((event) => TimeUtils.truncateDate(event.start, "day"));
            return buildGroupEventList();
          } else return noContent;
        } else return LoadingScreen();
      },
    );
  }
}

class _listGroup extends StatelessWidget {
  _listGroup(this.eventsGroup) {
    groupDate = TimeUtils.truncateDate(eventsGroup[0].start, "day");
  }

  final List<Event> eventsGroup;
  final formatter = new DateFormat('MMMM yyyy', 'it_IT');
  late DateTime groupDate;

  @override
  Widget build(BuildContext context) {

    void _onDayPressed() {
      PlatformUtils.navigator(context, Constants.homeRoute, {'day' : groupDate, 'operator' : null});
    }

    List<Widget> dateHeader = [
      Row(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 10),
            child: Text(groupDate.day.toString(), style: title2),
          ),
          Expanded(
            flex: 10,
            child: Text(formatter.format(groupDate).toUpperCase(), style: subtitle2),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
                icon: new Icon(Icons.today),
                alignment: Alignment.centerRight,
                color: Colors.grey,
                onPressed: _onDayPressed),
          ),
        ],
      ),
      Row(children: <Widget>[
        Expanded(
            flex: 9,
            child: Center(
                child: new Container(
                    margin: const EdgeInsets.only(
                        left: 10.0, right: 10.0, top: 0.0, bottom: 15.0),
                    child: Divider(color: Colors.grey, height: 0))))
      ])
    ];

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ...dateHeader,
            ...eventsGroup.map((event) => _listTileEvent(event)).expand((element) => [element, SizedBox(height: 20,)]).toList(),
            SizedBox(height: 10,)
          ]
      );
    }
}

class _listTileEvent extends StatelessWidget {
  _listTileEvent(this.event);

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Expanded(
        flex: 9,
        child: CardEvent(
          event: event,
          height: 160,
          showEventDetails: true,
          buttonArea: <String,Function(Event)>{
            "RIFIUTA": (event) async {RefuseAlert(context).show().then((justification)=>!string.isNullOrEmpty(justification)?context.read<WaitingEventListCubit>().cardActionRefuse(event, justification):null);},
            "ACCETTA":context.read<WaitingEventListCubit>().cardActionConfirm},
          onTapAction: (event) => PlatformUtils.navigator(context, Constants.detailsEventViewRoute, event),
        ),
      ),
      SizedBox(height: 15)
    ]);
  }
}
