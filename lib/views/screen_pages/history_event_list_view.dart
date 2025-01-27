/*
THIS IS THE MAIN PAGE OF THE OPERATOR
-l'appBar contiene menu a sinistra, titolo al centro
-in alto c'è una riga di giorni della settimana selezionabili
-(R)al centro e in basso c'è una grglia oraria dove sono rappresentati gli eventi dell'operatore corrente del giorno selezionato in alto
-(O)al centro e in basso c'è una grglia oraria dove sono rappresentati i propri eventi del giorno selezionato in alto
 */

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/cubit/history_event_list/history_event_list_cubit.dart';
import 'package:venturiautospurghi/cubit/web/history_page/history_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/dataTable/event_data_table.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/colors.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';
import 'package:venturiautospurghi/utils/headers_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/card_event_widget.dart';
import 'package:venturiautospurghi/views/widgets/chart/BadgePieChart.dart';
import 'package:venturiautospurghi/views/widgets/chart/BadgePieChartText.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_events_widget.dart';
import 'package:venturiautospurghi/views/widgets/flat_tab_widget.dart';
import 'package:venturiautospurghi/views/widgets/responsive_widget.dart';
import 'package:venturiautospurghi/views/widgets/table/pagination_table.dart';

class HistoryEventList extends StatelessWidget{

  final int? selectedStatus;
  HistoryEventList([this.selectedStatus]);

  @override
  Widget build(BuildContext context) {
    CloudFirestoreService repository = context.read<CloudFirestoreService>();

    return new BlocProvider(
        create: (_) => HistoryEventListCubit(repository, selectedStatus),
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
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Widget> _listHeaderContacts = [];
  Future ft = Future(() {});
  Tween<Offset> _offset = Tween(begin: Offset(1,0), end: Offset(0,0));
  List<PieChartSectionData> _listPieSection = [];
  List<PieChartSectionData> _listPieSectionCategory = [];

  _largeScreenState();

  _addWidgetHeaderHistory(){
    _listHeaderContacts = [];
    _listKey.currentState?.removeAllItems((context, animation) => Container());
    tabsHeaders.forEach((header) {
      ft = ft.then((_) {
        return Future.delayed(const Duration(milliseconds: 100), () {
          _listHeaderContacts.add(_headerWidget(header));
          _listKey.currentState?.insertItem(_listHeaderContacts.length -1);
        });
      });
    });
  }

  void _listPieChartSectionData(){
    _listPieSection.clear();
    tabsHeaders.forEach((header) {
      if (header.value != 0) {
        _listPieSection.add(_PieChartSectionDataWidget(header));
      }
    });
  }

  void _listPieChartSectionDataCategory(){
    _listPieSectionCategory.clear();
    int count = 0;
    context.read<WebCubit>().historyPageCubit.categories.forEach((key, color) {
        _listPieSectionCategory.add(_PieChartSectionDataWidgetCategory(key, color, count));
        count++;
    });
  }

  Widget _headerWidget(MapEntry<Tab,int> mapEntry){
    return BlocBuilder<WebCubit, WebCubitState>(
        buildWhen: (previous, current) =>
        previous.historyPageState.selectedStatusTab != current.historyPageState.selectedStatusTab
            || previous.historyPageState.countEntity != current.historyPageState.countEntity,
        builder: (context, state) {
          return Container(margin: EdgeInsets.symmetric(vertical: 5),child: FlatFab(mapEntry, selectedStatus: state.historyPageState.selectedStatusTab,
            onStatusTabSelected: context.read<WebCubit>().historyPageCubit.onStatusTabSelected,
            count: (state.historyPageState.countEntity[mapEntry.value]??0),)
          );
        });
  }

  PieChartSectionData _PieChartSectionDataWidgetCategory(String key, String color, int count){
    int status = context.read<WebCubit>().state.historyPageState.selectedStatusTab;
    bool active = context.read<WebCubit>().state.historyPageState.selectedCategory.contains(key);
    int tot = context.read<WebCubit>().state.historyPageState.countEntity[status]??1;
    int value = context.read<WebCubit>().state.historyPageState.countEventsArchivesCateogry[key]??0;
    int perceptual = DoubleUtils.roundUpIfOverHalf((100 * value) / tot);

    return PieChartSectionData(
      color: EventStatus.getColorDefault(count),
      value: perceptual.toDouble(),
      title: perceptual.toString()+'%',
      radius: active?60:50.0,
      titleStyle: TextStyle(
        fontSize: active?15:13.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xffffffff),
      ),
      badgeWidget: BadgePieChartText(
        value.toString(),
        size: active?35:30.0,
        borderColor: grey_light,
        active: active,
        tooltipText: key,
        backgroundColor: HexColor(color),
      ),
      badgePositionPercentageOffset: 1.05,
    );
  }

  PieChartSectionData _PieChartSectionDataWidget(MapEntry<Tab,int> mapEntry){
    bool active = context.read<WebCubit>().state.historyPageState.selectedStatusTab == mapEntry.value;
    int tot = context.read<WebCubit>().state.historyPageState.countEntity[-99]??1;
    int value = context.read<WebCubit>().state.historyPageState.countEntity[mapEntry.value]??0;
    int perceptual = DoubleUtils.roundUpIfOverHalf((100 * value) / tot);

    return PieChartSectionData(
      color: EventStatus.getColorArichive(mapEntry.value),
      value: perceptual.toDouble(),
      title: perceptual.toString()+'%',
      radius: active?60:50.0,
      titleStyle: TextStyle(
        fontSize: active?15:13.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xffffffff),
      ),
      badgeWidget: BadgePieChart(
        (mapEntry.key.icon as Icon).icon,
        size: active?35:30.0,
        borderColor: grey_light,
        active: active,
        tooltipText: (mapEntry.key.text??'').toLowerCase().capitalize(),
      ),
      badgePositionPercentageOffset: 1.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _addWidgetHeaderHistory();
    });
    return BlocBuilder <WebCubit, WebCubitState>(
          buildWhen: (previous, current) => previous.historyPageState != current.historyPageState,
          builder: (context, state) {
          return !(state.historyPageState is ReadyHistoryPageState) ? Center(child: CircularProgressIndicator()) : Container(
            child:Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 240,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text("Archivi", style: title,),
                        SizedBox(height: 10,),
                        AnimatedList(
                          shrinkWrap: true,
                          key: _listKey,
                          initialItemCount: _listHeaderContacts.length,
                          itemBuilder: (context, i, animation) => SlideTransition(
                            position: animation.drive(_offset),
                            child: _listHeaderContacts[i],
                          ),
                        ),
                        SizedBox(height: 10,),
                        Divider(
                          color: grey_light2,
                          thickness: 1,
                          height: 0,
                          indent: 10,
                          endIndent: 10,
                        ),
                        SizedBox(height: 10,),
                        BlocBuilder<WebCubit, WebCubitState>(
                            buildWhen: (previous, current) =>
                            previous.historyPageState.countEntity != current.historyPageState.countEntity
                                || previous.historyPageState.selectedStatusTab != current.historyPageState.selectedStatusTab,
                            builder: (context, state) {
                              _listPieChartSectionData();
                              return Expanded(
                                  flex: 2,
                                  child: Padding(padding: EdgeInsets.symmetric(vertical: 5) ,child:PieChart(
                                    PieChartData(
                                      startDegreeOffset: -90,
                                      pieTouchData: PieTouchData(
                                          mouseCursorResolver: (event, pieTouchResponse) => event is FlPointerHoverEvent?SystemMouseCursors.click:SystemMouseCursors.basic,
                                          touchCallback: (event, pieTouchResponse) => event is FlTapDownEvent?context.read<WebCubit>().historyPageCubit.onTouchPieChart(event,pieTouchResponse):null
                                      ),
                                      borderData: FlBorderData(
                                          show: true,
                                          border: Border.all(color: grey, width: 1)
                                      ),
                                      sectionsSpace: 5,
                                      centerSpaceRadius: 30,
                                      sections: _listPieSection,
                                    ),
                                  )));
                            }),
                        SizedBox(height: 5,),
                        Text("Categorie", style: title,),
                        SizedBox(height: 10,),
                        BlocBuilder<WebCubit, WebCubitState>(
                            buildWhen: (previous, current) =>
                            previous.historyPageState.countEventsArchivesCateogry != current.historyPageState.countEventsArchivesCateogry
                                || previous.historyPageState.selectedCategory != current.historyPageState.selectedCategory,
                            builder: (context, state) {
                              _listPieChartSectionDataCategory();
                              return Expanded(
                                  flex: 2,
                                  child: Padding(padding: EdgeInsets.symmetric(vertical: 5),
                                      child: PieChart(
                                    PieChartData(
                                      startDegreeOffset: -90,
                                      pieTouchData: PieTouchData(
                                          mouseCursorResolver: (event, pieTouchResponse) => event is FlPointerHoverEvent?SystemMouseCursors.click:SystemMouseCursors.basic,
                                          touchCallback: (event, pieTouchResponse) => event is FlTapDownEvent?context.read<WebCubit>().historyPageCubit.onTouchPieChartCategory(event,pieTouchResponse):null
                                      ),
                                      borderData: FlBorderData(
                                          show: true,
                                          border: Border.all(color: grey, width: 1)
                                      ),
                                      sectionsSpace: 5,
                                      centerSpaceRadius: 30,
                                      sections: _listPieSectionCategory,
                                    ),
                                  )));
                            }),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text("Tutti Gli Incarichi "+EventStatus.getCategoryText(state.historyPageState.selectedStatusTab), style: title, textAlign: TextAlign.left,),
                        SizedBox(height: 10,),
                        (context.read<WebCubit>().state.historyPageState as ReadyHistoryPageState).selectedEvents().isNotEmpty?
                          BlocBuilder<WebCubit, WebCubitState>(
                              buildWhen: (previous, current) => previous.historyPageState.numPage != current.historyPageState.numPage,
                              builder: (context, state) {
                                return PaginationTable(new EventDataTable((context.read<WebCubit>().state.historyPageState as ReadyHistoryPageState).selectedEvents(),
                                    (context.read<WebCubit>().state.historyPageState as ReadyHistoryPageState).countEvents(),
                                    onSelected: (event, bool) => PlatformUtils.navigator(context, Constants.detailsEventViewRoute, <String,dynamic>{"objectParameter" :event})),
                                  ['','Tipo','Titolo','Data','Operatori','Cliente','Indirizzo','Telefoni'],
                                  firstRowIndex: state.historyPageState.numPage,
                                  showCheckboxColumn: false,
                                  handleNext: context.read<WebCubit>().historyPageCubit.nextPage,
                                  handlePrevious: context.read<WebCubit>().historyPageCubit.previousPage,
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
                  ),
                )
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