/*
THIS IS THE MAIN PAGE OF THE OPERATOR
-l'appBar contiene menu a sinistra, titolo al centro
-in alto c'è una riga di giorni della settimana selezionabili
-(R)al centro e in basso c'è una grglia oraria dove sono rappresentati gli eventi dell'operatore corrente del giorno selezionato in alto
-(O)al centro e in basso c'è una grglia oraria dove sono rappresentati i propri eventi del giorno selezionato in alto
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/cubit/history_event_list/history_event_list_cubit.dart';
import 'package:venturiautospurghi/cubit/web/history_page/history_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/dataTable/event_data_table.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/headers_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/card_event_widget.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_events_widget.dart';
import 'package:venturiautospurghi/views/widgets/flat_tab_widget.dart';
import 'package:venturiautospurghi/views/widgets/responsive_widget.dart';
import 'package:venturiautospurghi/views/widgets/table/pagination_table.dart';

class HistoryEventList extends StatefulWidget {

  final int? selectedStatus;
  HistoryEventList([this.selectedStatus]);

  @override
  _HistoryEventListState createState() => _HistoryEventListState();
}

class _HistoryEventListState extends State<HistoryEventList> {

  @override
  void initState() {
    super.initState();
    if(!PlatformUtils.isMobile) {
      context.read<WebCubit>().initCubit(Constants.historyEventListRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    CloudFirestoreService repository = context.read<CloudFirestoreService>();

    return new BlocProvider(
        create: (_) => HistoryEventListCubit(repository, widget.selectedStatus),
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
  final List<MapEntry<Tab,int>> tabsHeaders = Headers.tabsHeadersHistory;
  Future ft = Future(() {});

  _largeScreenState();

  Widget _headerWidget(MapEntry<Tab,int> mapEntry){
    return BlocBuilder<WebCubit, WebCubitState>(
        buildWhen: (previous, current) =>
        previous.historyPageState.selectedStatusTab != current.historyPageState.selectedStatusTab
            || previous.historyPageState.countEntity != current.historyPageState.countEntity,
        builder: (context, state) {
          return Container(margin: EdgeInsets.symmetric(vertical: 5),child: FlatFab(mapEntry, selectedStatus: state.historyPageState.selectedStatusTab,
            onStatusTabSelected: context.read<WebCubit>().historyPageCubit.onStatusTabSelected,
            count: (state.historyPageState.countEntity[mapEntry.value]??0), horizontalMode: true,)
          );
        });
  }

  Widget _buildCard(String titleText, VoidCallback onTap, int count) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
        color: white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    if (titleText.contains('\n'))
                      TextSpan(
                        text: titleText.split('\n')[0] + '\n',
                        style: title.copyWith(fontSize: 16, color: grey_light, fontWeight: FontWeight.normal),
                      ),
                    TextSpan(
                      text: titleText.contains('\n') ? titleText.split('\n')[1] : titleText,
                      style: title.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: black, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(count.toString(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              )
            ],
          ),
        ),
      )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder <WebCubit, WebCubitState>(
          buildWhen: (previous, current) => 
              previous.historyPageState != current.historyPageState ||
              previous.historyPageState.runtimeType != current.historyPageState.runtimeType,
          builder: (context, state) {
          final historyState = state.historyPageState;

          List<String> monthNames = ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'];

          return Container(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        height: 70,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: tabsHeaders.map((header) => Padding(
                              padding: const EdgeInsets.only(right: 15.0),
                              child: _headerWidget(header),
                            )).toList(),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Row(
                          children: [
                            MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                    onTap: () => context.read<WebCubit>().historyPageCubit.selectYear(null),
                                    child: Text(
                                        tabsHeaders.firstWhere((e) => e.value == historyState.selectedStatusTab).key.text!.toLowerCase().capitalize(),
                                        style: title.copyWith(color: grey_dark, fontWeight: historyState.selectedYear == null ? FontWeight.bold : FontWeight.normal)
                                    )
                                )
                            ),
                            if(historyState.selectedYear != null) ...[
                              Icon(Icons.chevron_right, color: grey_dark, size: 25),
                              MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                      onTap: () => context.read<WebCubit>().historyPageCubit.selectMonth(null),
                                      child: Text("Anno ${historyState.selectedYear}", style: title.copyWith(color: historyState.selectedMonth == null ? grey_dark : grey_dark, fontWeight: historyState.selectedMonth == null ? FontWeight.bold : FontWeight.normal))
                                  )
                              )
                            ],
                            if(historyState.selectedMonth != null) ...[
                              Icon(Icons.chevron_right, color: grey_dark, size: 25),
                              Text(monthNames[historyState.selectedMonth!-1], style: title.copyWith(color: grey_dark, fontWeight: FontWeight.bold))
                            ]
                          ]
                      ),
                    ],
                  ),
                  SizedBox(height: 15,),
                  Expanded(
                    child: historyState is! ReadyHistoryPageState ? Center(child: CircularProgressIndicator()) : historyState.selectedYear == null ?
                    Builder(builder: (context) {
                      final filteredYears = historyState.availableYears.where((year) => (historyState.yearCounts[year] ?? 0) > 0).toList();
                      return filteredYears.isNotEmpty ? GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 160,
                        ),
                        itemCount: filteredYears.length,
                        itemBuilder: (context, index) {
                          int year = filteredYears[index];
                          return _buildCard("Anno\n$year", () => context.read<WebCubit>().historyPageCubit.selectYear(year), historyState.yearCounts[year] ?? 0);
                        },
                      ) : Center(child: Text("Nessun incarico da mostrare", style: title));
                    }) : historyState.selectedMonth == null ?
                    Builder(builder: (context) {
                      final filteredMonths = List.generate(12, (index) => index + 1).where((m) => (historyState.monthCounts[m] ?? 0) > 0).toList();
                      return filteredMonths.isNotEmpty ? GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 180,
                        ),
                        itemCount: filteredMonths.length,
                        itemBuilder: (context, index) {
                          int month = filteredMonths[index];
                          return _buildCard(monthNames[month - 1], () => context.read<WebCubit>().historyPageCubit.selectMonth(month), historyState.monthCounts[month] ?? 0);
                        },
                      ) : Center(child: Text("Nessun incarico da mostrare", style: title));
                    }) :
                    Builder(builder: (context) {
                      final readyState = historyState as ReadyHistoryPageState;
                      final events = readyState.selectedEvents();
                      return events.isNotEmpty
                        ? PaginationTable(
                            EventDataTable(
                              events,
                              readyState.countEvents(),
                              onSelected: (event, bool) => PlatformUtils.navigator(context, Constants.detailsEventViewRoute, <String,dynamic>{"objectParameter": event}),
                            ),
                            ['','Tipo','Titolo','Data','Operatori','Cliente','Indirizzo','Telefoni'],
                            firstRowIndex: readyState.numPage,
                            showCheckboxColumn: false,
                            headingRowHeight: 40,
                            handleNext: context.read<WebCubit>().historyPageCubit.nextPage,
                            handlePrevious: context.read<WebCubit>().historyPageCubit.previousPage,
                          )
                        : Container(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Padding(padding: EdgeInsets.only(bottom: 5), child: Text("Nessun incarico da mostrare", style: title,)),
                              ],
                            ),
                          );
                    }),
                  ),
                ],
              ),
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

  late TabController _tabController;
  final List<MapEntry<Tab,int>> tabsHeaders = Headers.tabsHeadersHistory;

  _smallScreenState();

  @override
  void initState() {
    _tabController = new TabController(vsync: this, length: tabsHeaders.length);
    context.read<HistoryEventListCubit>().scrollController.addListener(() {
      if (context.read<HistoryEventListCubit>().scrollController.position.pixels == context.read<HistoryEventListCubit>().scrollController.position.maxScrollExtent) {
        if(context.read<HistoryEventListCubit>().canLoadMore[context.read<HistoryEventListCubit>().state.selectedStatusTab]??false)
          context.read<HistoryEventListCubit>().loadMoreData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _tabController.addListener(() { //
      context.read<HistoryEventListCubit>().onStatusTabSelected(tabsHeaders[_tabController.index].value);
    });

    return Material(
      elevation: 12.0,
      borderRadius: new BorderRadius.only(
          topLeft: new Radius.circular(16.0),
          topRight: new Radius.circular(16.0)),
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
            Container(
              decoration: BoxDecoration(
                  color: whitebackground,
                  borderRadius: BorderRadius.all(
                      Radius.circular(30.0))),
              child: new TabBar(
                unselectedLabelColor: black,
                labelStyle: title.copyWith(fontSize: 16),
                labelColor: black,
                indicatorColor: yellow,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: tabsHeaders.map((pair) => pair.key).toList(),
                controller: _tabController,
              ),
            ),
          EventsFilterWidget(
            hintTextSearch: 'Cerca gli interventi',
            onSearchFieldChanged: context.read<HistoryEventListCubit>().onFiltersChanged,
            onFiltersChanged: context.read<HistoryEventListCubit>().onFiltersChanged,
          ),
            !PlatformUtils.isMobile ?
              Container(
                child: _historyContent(_tabController, tabsHeaders),
                height: MediaQuery.of(context).size.height - 150,) :
              Expanded(
                child: _historyContent(_tabController, tabsHeaders)
              )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    context.read<HistoryEventListCubit>().scrollController.dispose();
    super.dispose();
  }
}

class _historyContent extends StatelessWidget {
  TabController _tabController;

  final List<MapEntry<Tab,int>> tabsHeaders;

  _historyContent(this._tabController, this.tabsHeaders);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryEventListCubit, HistoryEventListState>(
    buildWhen: (previous, current) => previous != current,
    builder: (context, state) {
      return !(state is HistoryReady) ? Center(child: CircularProgressIndicator()) :
      TabBarView(
        controller: _tabController,
        children:
         tabsHeaders.map((e) =>  Padding(
            padding: EdgeInsets.all(15.0),
          child:state.events(e.value).length>0 ?
          ListView.separated(
            controller: context.read<HistoryEventListCubit>().scrollController,
            separatorBuilder: (context, index) => SizedBox(height: 10,),
            physics: BouncingScrollPhysics(),
            padding: new EdgeInsets.symmetric(vertical: 8.0),
            itemCount: state.events(e.value).length+1,
            itemBuilder: (context, index) => index != state.events(e.value).length?
          Container(
                child: CardEvent(
                  event: state.events(e.value)[index],
                  height: 120,
                  showEventDetails: true,
                  onTapAction: (event) => PlatformUtils.navigator(context, Constants.detailsEventViewRoute, event),
                )
              ) :
          context.read<HistoryEventListCubit>().canLoadMore[e.value]!? Center(
          child: Container(
            margin: new EdgeInsets.symmetric(vertical: 13.0),
            height: 26,
            width: 26,
            child: CircularProgressIndicator(),
          )):Container()
            ):Container(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(padding: EdgeInsets.only(bottom: 5) ,child:Text("Nessun incarico da mostrare",style: title,)),
              ],
            ),
          )
      ),).toList()
      );
    });
  }
}


