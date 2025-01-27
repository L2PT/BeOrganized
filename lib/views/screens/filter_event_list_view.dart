import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/cubit/event_filter_view/filter_event_list_cubit.dart';
import 'package:venturiautospurghi/cubit/web/event_list_page/event_list_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/dataTable/event_data_table.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_delete.dart';
import 'package:venturiautospurghi/views/widgets/card_event_widget.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_events_widget.dart';
import 'package:venturiautospurghi/views/widgets/responsive_widget.dart';
import 'package:venturiautospurghi/views/widgets/table/pagination_table.dart';

class FilterEventList extends StatelessWidget {

  bool isBozze;

  FilterEventList({this.isBozze = false});

  @override
  Widget build(BuildContext context) {
    CloudFirestoreService repository = context.read<CloudFirestoreService>();
    Account account = context.read<AuthenticationBloc>().account!;
    return new BlocProvider(
        create: (_) => FilterEventListCubit(repository, account, isBozze: this.isBozze),
        child: ResponsiveWidget(
          smallScreen: _smallScreen(),
          largeScreen: _largeScreen(),
        ));
  }
}

class _largeScreen extends StatefulWidget {

  _largeScreen();

  @override
  State<StatefulWidget> createState() => _largeScreenState();

}

class _largeScreenState extends State<_largeScreen>  {

  void deleteEvent(Event event, BuildContext context){
    ConfirmCancelAlert(context, title: "CANCELLA INCARICO", text: "Confermi la cancellazione del incarico?").show().then((value) {
      if(value.first){
        context.read<WebCubit>().eventListPageCubit.deleteEvent(event);
      }
    });
  }

  void deleteAllCustomer(BuildContext context){
    ConfirmCancelAlert(context, title: "CANCELLA GLI INCARICHI", text: "Confermi la cancellazione degli incarichi selezionati?").show().then((value) {
      if(value.first){
        context.read<WebCubit>().eventListPageCubit.deleteAllEvent();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder <WebCubit, WebCubitState>(
        buildWhen: (previous, current) => previous.eventListPageState != current.eventListPageState,
        builder: (context, state) {
          return !(state.eventListPageState is ReadyEventListPageState) ? Center(child: CircularProgressIndicator()) : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: [
                    Text("Tutti Gli Incarichi ", style: title, textAlign: TextAlign.left),
                    Expanded(child: Container()),
                    BlocBuilder<WebCubit, WebCubitState>(
                        buildWhen: (previous, current) => previous.eventListPageState.mapSelected != current.eventListPageState.mapSelected ||
                            previous.eventListPageState.numPage != current.eventListPageState.numPage,
                        builder: (context, state) {
                          return AnimatedContainer(
                            curve: Curves.easeInOut,
                            duration: Duration(milliseconds: 500),
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: AnimatedOpacity(
                                opacity: context.read<WebCubit>().eventListPageCubit.isSelected() ? 1.0 : 0.0, // Opacità cambia a 0
                                duration: Duration(milliseconds: 500),
                                child: ElevatedButton(
                                    style: raisedButtonStyle.copyWith(
                                        padding: WidgetStateProperty.all<EdgeInsets>(
                                            EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
                                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0),),)),
                                    onPressed: () => deleteAllCustomer(context),
                                    child: Row(
                                      children: <Widget>[
                                        Icon(Icons.delete, color: white,),
                                        SizedBox(width: 5),
                                        Text("Cancella tutti", style: subtitle_rev,),
                                      ],
                                    )
                                )),
                          );
                        })
                  ],
                ),
                SizedBox(height: 10,),
                (context.read<WebCubit>().state.eventListPageState as ReadyEventListPageState).selectedEvents().isNotEmpty?
                BlocBuilder<WebCubit, WebCubitState>(
                    buildWhen: (previous, current) => previous.eventListPageState.numPage != current.eventListPageState.numPage || previous.eventListPageState.isBozze != current.eventListPageState.isBozze,
                    builder: (context, state) {
                      return PaginationTable(new EventDataTable((context.read<WebCubit>().state.eventListPageState as ReadyEventListPageState).selectedEvents(),
                          context.read<WebCubit>().state.eventListPageState.totalEvent,
                          onDetail: (event) => PlatformUtils.navigator(context, Constants.detailsEventViewRoute, <String,dynamic>{"objectParameter" :event}),
                          onDelete: (event) => deleteEvent(event,context),
                          onEdit: (event) => PlatformUtils.navigator(context, Constants.createEventViewRoute,<String, dynamic>{'objectParameter' : event,
                            'typeStatus' : TypeStatus.modify},),
                          onSelected: state.eventListPageState.isBozze?context.read<WebCubit>().eventListPageCubit.onSelectedEvent
                              :(event, bool) => PlatformUtils.navigator(context, Constants.detailsEventViewRoute, <String,dynamic>{"objectParameter" :event}),
                          actionVisible: state.eventListPageState.isBozze, operatorVisible: !state.eventListPageState.isBozze,
                          mapSelected: context.read<WebCubit>().state.eventListPageState.mapSelected),
                        state.eventListPageState.isBozze?['','Tipo','Titolo','Data','Cliente','Indirizzo','Telefoni', 'Azioni']:
                        ['','Tipo','Titolo','Data','Operatori','Cliente','Indirizzo','Telefoni'],
                        firstRowIndex: state.eventListPageState.numPage,
                        showCheckboxColumn: state.eventListPageState.isBozze,
                        selectAll: context.read<WebCubit>().eventListPageCubit.onSelectedAllEvent,
                        handleNext: context.read<WebCubit>().eventListPageCubit.nextPage,
                        handlePrevious: context.read<WebCubit>().eventListPageCubit.previousPage,
                      );
                    })
                    : Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(padding: EdgeInsets.only(bottom: 5) ,child:Text("Nessun incarico da mostrare",style: title,)),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}

class _smallScreen extends StatefulWidget {

  _smallScreen();

  @override
  State<StatefulWidget> createState() => _smallScreenState();

}

class _smallScreenState extends State<_smallScreen> with TickerProviderStateMixin {

  @override
  void initState() {
    context.read<FilterEventListCubit>().scrollController.addListener(() {
      if (context.read<FilterEventListCubit>().scrollController.position.pixels == context.read<FilterEventListCubit>().scrollController.position.maxScrollExtent) {
        if(context.read<FilterEventListCubit>().canLoadMore)
          context.read<FilterEventListCubit>().loadMoreData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12.0,
      borderRadius: new BorderRadius.only(
          topLeft: new Radius.circular(16.0),
          topRight: new Radius.circular(16.0)),
      child: Column(
        children: [
          SizedBox(height: 15,),
          EventsFilterWidget(
            hintTextSearch: 'Cerca gli interventi',
            onSearchFieldChanged: context.read<FilterEventListCubit>().onFiltersChanged,
            onFiltersChanged: context.read<FilterEventListCubit>().onFiltersChanged,
          ),
          BlocBuilder<FilterEventListCubit, FilterEventListState>(
              buildWhen: (previous, current) => previous != current,
              builder: (context, state) {
                return !(state is ReadyFilterEventList) ? Center(
                    child: CircularProgressIndicator()) : state.listEventFiltered.length > 0 ?
                Expanded(child: Padding(
                    padding: EdgeInsets.all(15.0),
                    child: ListView.separated(
                        controller: context.read<FilterEventListCubit>().scrollController,
                        separatorBuilder: (context, index) => SizedBox(height: 10,),
                        physics: BouncingScrollPhysics(),
                        padding: new EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: state.listEventFiltered.length+1,
                        itemBuilder: (context, index) => index != state.listEventFiltered.length?
                        Container(
                          child: CardEvent(
                            event: state.listEventFiltered[index],
                            height: 120,
                            showEventDetails: true,
                            onTapAction: (event) => PlatformUtils.navigator(context, Constants.detailsEventViewRoute, event)
                          )
                        ) : context.read<FilterEventListCubit>().canLoadMore?
                        Center(
                          child: Container(
                            margin: new EdgeInsets.symmetric(vertical: 13.0),
                            height: 26,
                            width: 26,
                            child: CircularProgressIndicator(),
                        )):Container()
                    ))) : Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(padding: EdgeInsets.only(bottom: 5),
                          child: Text(
                            "Nessun incarico da mostrare", style: title,)),
                    ],
                  ),
                );
              })
        ],
      ),);
  }

  @override
  void dispose() {
    context.read<FilterEventListCubit>().scrollController.dispose();
    super.dispose();
  }

}
